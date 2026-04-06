#!/usr/bin/env python3
"""Astropolis Interface test runner.

Runs the generic I, Voyager tests first, then Astropolis-specific tests that
interrogate Interface instances and their net component data.

Usage:
    python test_interfaces.py                  # game already running
    python test_interfaces.py --launch         # start Godot automatically
    python test_interfaces.py --economy        # include economy test (~120s)
    python test_interfaces.py --skip-save      # skip generic save/load cycle
"""

import argparse
import os
import subprocess
import sys
import time

# Import generic test infrastructure from the assistant plugin
sys.path.insert(0, os.path.join(os.path.dirname(__file__),
                                "..", "..", "addons", "ivoyager_assistant", "tools"))
from assistant_test import AssistantClient, TestRunner as GenericTestRunner


class AstropolisTestRunner:
    """Astropolis-specific tests that run after the generic I, Voyager tests."""

    def __init__(self, client, generic_runner):
        self.client = client
        self.g = generic_runner  # reuse its assertion helpers and counters

    def run_all(self, economy=False):
        print("\n=== Astropolis Interface Tests ===\n")

        self.test_astropolis_capability()
        self.test_list_interfaces()
        self.test_interface_info()
        self.test_instant_development_stats()
        self.test_short_time_stats()
        self.test_list_components()
        self.test_inspect_operations()
        self.test_inspect_population()
        self.test_inspect_biome()
        self.test_query_component()
        self.test_component_errors()
        if economy:
            self.test_economy_stats()
        else:
            print("[test_economy_stats] SKIPPED (use --economy to enable)")

    def test_astropolis_capability(self):
        print("[test_astropolis_capability]")
        self.g.assert_true(
            self.g.has_cap("astropolis_interfaces"),
            "AstropolisTestSuite capability registered"
        )

    def test_list_interfaces(self):
        print("[test_list_interfaces]")
        resp = self.client.call("list_interfaces", {"has_development": True})
        result = resp.get("result", {})
        interfaces = result.get("interfaces", [])
        names = [i["name"] for i in interfaces]
        self.g.assert_true("PLANET_EARTH" in names, "PLANET_EARTH in interface list")
        self.g.assert_true("JOIN_OFFWORLD" in names, "JOIN_OFFWORLD in interface list")
        self.g.assert_true(
            len(interfaces) > 2,
            "Multiple interfaces with development (%d found)" % len(interfaces)
        )

    def test_interface_info(self):
        print("[test_interface_info]")
        for name in ("PLANET_EARTH", "JOIN_OFFWORLD"):
            resp = self.client.call("get_interface_info", {"name": name})
            result = resp.get("result", {})
            self.g.assert_true("error" not in resp, "%s interface found" % name)
            self.g.assert_true(result.get("has_development", False),
                               "%s has development" % name)
            self.g.assert_true(result.get("has_operations", False),
                               "%s has operations" % name)
            self.g.assert_true(result.get("has_population", False),
                               "%s has population" % name)
            self.g.assert_true(result.get("has_biome", False),
                               "%s has biome" % name)

    def test_instant_development_stats(self):
        print("[test_instant_development_stats]")
        for name in ("PLANET_EARTH", "JOIN_OFFWORLD"):
            resp = self.client.call("get_development_stats", {"name": name})
            result = resp.get("result", {})
            self.g.assert_true("error" not in resp,
                               "%s development stats returned" % name)
            self.g.assert_gt(result.get("population", 0), 0, "%s.population" % name)
            self.g.assert_gt(result.get("constructions", 0), 0,
                             "%s.constructions" % name)
            self.g.assert_gt(result.get("information", 0), 0, "%s.information" % name)
            self.g.assert_gt(result.get("biomass", 0), 0, "%s.biomass" % name)
            self.g.assert_gt(result.get("biodiversity", 0), 0,
                             "%s.biodiversity" % name)
            if name == "PLANET_EARTH":
                self.g.assert_gt(result.get("bioproductivity", 0), 0,
                                 "%s.bioproductivity" % name)
            else:
                self.g.assert_eq(result.get("bioproductivity", -1), 0.0,
                                 "%s.bioproductivity (spacecraft have no biome)" % name)
            self.g.assert_eq(result.get("computation", -1), 0.0,
                             "%s.computation (not yet populated)" % name)

    def _advance_time_days(self, days, speed_index=6):
        """Advance simulation by approximately `days` game-days."""
        resp = self.client.call("get_time")
        start_time = resp.get("result", {}).get("time", 0)
        target_time = start_time + days * 86400

        self.client.call("set_pause", {"paused": False})
        self.client.call("set_speed", {"index": speed_index})

        for attempt in range(60):
            resp = self.client.call("get_time")
            current_time = resp.get("result", {}).get("time", 0)
            if current_time >= target_time:
                self.client.call("set_speed", {"index": 0})
                elapsed_days = (current_time - start_time) / 86400
                print("  Advanced %d game-days in %d polls" % (
                    int(elapsed_days), attempt + 1))
                return True
            time.sleep(0.5)

        self.client.call("set_speed", {"index": 0})
        return False

    def test_short_time_stats(self):
        """Stats that need ~1 game week: power, manufacturing."""
        print("[test_short_time_stats]")
        if not self._advance_time_days(10):
            self.g.assert_true(False, "Time advanced 10 days (timed out)")
            return

        resp = self.client.call("get_development_stats", {"name": "PLANET_EARTH"})
        result = resp.get("result", {})
        self.g.assert_gt(result.get("power", 0), 0,
                         "PLANET_EARTH.power (after ~10 days)")
        self.g.assert_gt(result.get("manufacturing", 0), 0,
                         "PLANET_EARTH.manufacturing (after ~10 days)")

    def test_list_components(self):
        """Verify list_components returns correct component metadata."""
        print("[test_list_components]")
        resp = self.client.call("list_components", {"name": "PLANET_EARTH"})
        result = resp.get("result", {})
        self.g.assert_true("error" not in resp,
                           "list_components returned successfully")
        components = result.get("components", {})
        self.g.assert_true(components.get("operations", {}).get("present", False),
                           "PLANET_EARTH has operations component")
        self.g.assert_true(components.get("population", {}).get("present", False),
                           "PLANET_EARTH has population component")
        self.g.assert_true(components.get("biome", {}).get("present", False),
                           "PLANET_EARTH has biome component")

        ops_info = components.get("operations", {})
        self.g.assert_true(ops_info.get("index_table") == "operations",
                           "operations index_table is 'operations'")
        self.g.assert_gt(ops_info.get("n_indices", 0), 0,
                         "operations n_indices > 0 (%d)" % ops_info.get("n_indices", 0))

    def test_inspect_operations(self):
        """Inspect OperationsNet data with nonzero filter."""
        print("[test_inspect_operations]")
        resp = self.client.call("inspect_component", {
            "name": "PLANET_EARTH",
            "component": "operations",
            "nonzero": True,
        })
        result = resp.get("result", {})
        self.g.assert_true("error" not in resp,
                           "inspect_component operations returned successfully")
        entries = result.get("entries", {})
        n_total = result.get("n_total", 0)
        n_returned = result.get("n_returned", 0)

        self.g.assert_gt(n_returned, 0,
                         "Operations has nonzero entries (%d)" % n_returned)
        self.g.assert_gt(n_total, n_returned,
                         "Nonzero filter reduced entries (%d total -> %d)"
                         % (n_total, n_returned))

        # Verify entry structure
        has_capacity = False
        for op_name, fields in entries.items():
            self.g.assert_true("capacity" in fields,
                               "'capacity' field in entry '%s'" % op_name)
            self.g.assert_true("run_rate" in fields,
                               "'run_rate' field in entry '%s'" % op_name)
            self.g.assert_true("effective_rate" in fields,
                               "'effective_rate' field in entry '%s'" % op_name)
            cap = fields.get("capacity")
            if cap is not None and cap > 0:
                has_capacity = True
            break  # Only check first entry structure

        self.g.assert_true(has_capacity or n_returned > 0,
                           "At least some operations have data")

    def test_inspect_population(self):
        """Inspect PopulationNet data."""
        print("[test_inspect_population]")
        resp = self.client.call("inspect_component", {
            "name": "PLANET_EARTH",
            "component": "population",
            "nonzero": True,
        })
        result = resp.get("result", {})
        self.g.assert_true("error" not in resp,
                           "inspect_component population returned successfully")
        entries = result.get("entries", {})
        self.g.assert_gt(result.get("n_returned", 0), 0,
                         "Population has nonzero entries")

        # Verify at least one population type has number > 0
        has_pop = False
        for pop_name, fields in entries.items():
            number = fields.get("number")
            if number is not None and number > 0:
                has_pop = True
                break
        self.g.assert_true(has_pop, "At least one population type has number > 0")

    def test_inspect_biome(self):
        """Inspect BiomeNet scalar data."""
        print("[test_inspect_biome]")
        resp = self.client.call("inspect_component", {
            "name": "PLANET_EARTH",
            "component": "biome",
        })
        result = resp.get("result", {})
        self.g.assert_true("error" not in resp,
                           "inspect_component biome returned successfully")
        self.g.assert_true("bioproductivity" in result,
                           "bioproductivity in biome result")
        self.g.assert_true("biomass" in result,
                           "biomass in biome result")
        self.g.assert_true("biodiversity" in result,
                           "biodiversity in biome result")
        self.g.assert_true(result.get("component") == "biome",
                           "component field is 'biome'")

    def test_query_component(self):
        """Test targeted query with entry and field filters."""
        print("[test_query_component]")

        # First, get all nonzero operations to find a valid entry name
        resp = self.client.call("inspect_component", {
            "name": "PLANET_EARTH",
            "component": "operations",
            "nonzero": True,
        })
        entries = resp.get("result", {}).get("entries", {})
        if not entries:
            self.g.assert_true(False, "No operations entries to query")
            return

        target_name = list(entries.keys())[0]

        # Query that specific entry with specific fields
        resp = self.client.call("query_component", {
            "name": "PLANET_EARTH",
            "component": "operations",
            "entries": [target_name],
            "fields": ["capacity", "run_rate"],
        })
        result = resp.get("result", {})
        self.g.assert_true("error" not in resp,
                           "query_component returned successfully")
        q_entries = result.get("entries", {})
        self.g.assert_true(target_name in q_entries,
                           "Queried entry '%s' in result" % target_name)
        self.g.assert_eq(result.get("n_returned", 0), 1,
                         "Only 1 entry returned for single-entry query")

        # Verify field filter worked
        if target_name in q_entries:
            fields = q_entries[target_name]
            self.g.assert_true("capacity" in fields,
                               "'capacity' in filtered fields")
            self.g.assert_true("run_rate" in fields,
                               "'run_rate' in filtered fields")
            self.g.assert_true("effective_rate" not in fields,
                               "'effective_rate' excluded by field filter")

    def test_component_errors(self):
        """Test error handling for invalid queries."""
        print("[test_component_errors]")

        # Nonexistent interface
        resp = self.client.call("inspect_component", {
            "name": "DOES_NOT_EXIST",
            "component": "operations",
        })
        self.g.assert_true("error" in resp or "_error" in resp.get("result", {}),
                           "Error for nonexistent interface")

        # Invalid component name
        resp = self.client.call("inspect_component", {
            "name": "PLANET_EARTH",
            "component": "not_a_component",
        })
        self.g.assert_true("error" in resp or "_error" in resp.get("result", {}),
                           "Error for invalid component name")

        # Missing component parameter
        resp = self.client.call("inspect_component", {
            "name": "PLANET_EARTH",
        })
        self.g.assert_true("error" in resp or "_error" in resp.get("result", {}),
                           "Error for missing component parameter")

    def test_economy_stats(self):
        """Economy needs ~1 game year of LFQ data. Use --economy flag."""
        print("[test_economy_stats]")
        resp = self.client.call("get_time")
        date = resp.get("result", {}).get("date", [2025, 1, 1])
        print("  Current date: %s" % date)

        if not self._advance_time_days(730):
            self.g.assert_true(False, "Time advanced ~2 years (timed out)")
            return

        resp = self.client.call("get_development_stats", {"name": "PLANET_EARTH"})
        result = resp.get("result", {})
        self.g.assert_gt(result.get("economy", 0), 0,
                         "PLANET_EARTH.economy (after ~2 years)")

        resp = self.client.call("get_development_stats", {"name": "JOIN_OFFWORLD"})
        result = resp.get("result", {})
        self.g.assert_eq(result.get("economy", -1), 0.0,
                         "JOIN_OFFWORLD.economy (spacecraft have no gross output)")


def main():
    parser = argparse.ArgumentParser(description="Astropolis Interface Tests")
    parser.add_argument("--host", default="127.0.0.1", help="Server host")
    parser.add_argument("--port", type=int, default=29071, help="Server port")
    parser.add_argument("--launch", action="store_true",
                        help="Launch Godot before testing")
    parser.add_argument("--godot", default=None,
                        help="Path to Godot executable")
    parser.add_argument("--project", default=None,
                        help="Path to project directory")
    parser.add_argument("--economy", action="store_true",
                        help="Run economy test (needs ~2 game years, ~120s)")
    parser.add_argument("--skip-save", action="store_true",
                        help="Skip generic save/load cycle")
    args = parser.parse_args()

    godot_proc = None
    if args.launch:
        godot = args.godot or "../Godot_v4.6.2-stable_win64_console.exe"
        project = args.project or "."
        print("Launching Godot: %s --path %s" % (godot, project))
        godot_proc = subprocess.Popen([godot, "--path", project])

    client = AssistantClient(host=args.host, port=args.port)
    try:
        print("Connecting to %s:%d..." % (args.host, args.port))
        client.connect()
        print("Connected!")

        # Run generic I, Voyager tests first
        generic = GenericTestRunner(client, skip_save=args.skip_save)
        generic.run_all(print_summary=False)

        # Run Astropolis-specific tests (shares pass/fail counters)
        astropolis = AstropolisTestRunner(client, generic)
        astropolis.run_all(economy=args.economy)

        # Combined results
        print("\n=== Combined Results: %d passed, %d failed, %d skipped ===" % (
            generic.passed, generic.failed, generic.skipped))
        if generic.errors:
            print("\nFailures:")
            for err in generic.errors:
                print("  - %s" % err)

        success = generic.failed == 0

        # Quit the game
        print("\nSending quit...")
        client.call("quit", {"force": True})
    except Exception as e:
        print("\nERROR: %s" % e)
        success = False
    finally:
        client.close()
        if godot_proc:
            godot_proc.wait(timeout=10)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
