#!/usr/bin/env python3
"""Astropolis Interface test runner.

Runs the generic I, Voyager tests first, then Astropolis-specific tests that
interrogate Interface development statistics for PLANET_EARTH and JOIN_OFFWORLD.

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

    # Old op_group names that should NOT appear as group titles.
    OP_GROUP_NAMES = {
        "OP_GROUP_SOLAR_POWER", "OP_GROUP_GEOTHERMAL_POWER",
        "OP_GROUP_KINETIC_POWER", "OP_GROUP_COMBUSTION_POWER",
        "OP_GROUP_FUEL_CELLS", "OP_GROUP_NUCLEAR_POWER",
    }

    # Module names expected in the Energy tab (with MODULE_ prefix from table).
    ENERGY_MODULE_NAMES = {
        "MODULE_SOLAR_ARRAYS", "MODULE_GEOTHERMAL_PLANTS",
        "MODULE_HYDROELECTRIC_DAMS", "MODULE_WIND_FARMS",
        "MODULE_TIDAL_POWER_STATIONS", "MODULE_COMBUSTION_POWER_PLANTS",
        "MODULE_FUEL_CELLS", "MODULE_LEU_NUCLEAR_PLANTS",
        "MODULE_HEU_NUCLEAR_REACTORS", "MODULE_THORIUM_NUCLEAR_PLANTS",
        "MODULE_D_T_FUSION_PLANTS", "MODULE_D_3HE_FUSION_PLANTS",
        "MODULE_3HE_3HE_FUSION_PLANTS", "MODULE_RADIOISOTOPE_GENERATORS",
    }

    def run_all(self, economy=False):
        print("\n=== Astropolis Interface Tests ===\n")

        self.test_astropolis_capability()
        self.test_list_interfaces()
        self.test_interface_info()
        self.test_instant_development_stats()
        self.test_short_time_stats()
        self.test_operations_tab_modules()
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

    def test_operations_tab_modules(self):
        """Verify the Operations data groups by modules, not op_groups."""
        print("[test_operations_tab_modules]")

        # Energy tab = 0, query data layer for PLANET_EARTH
        resp = self.client.call("get_operations_tab",
                                {"name": "PLANET_EARTH", "tab": 0})
        result = resp.get("result", {})
        self.g.assert_true("error" not in resp,
                           "get_operations_tab returned successfully")

        groups = result.get("groups", [])
        group_names = [g["title"] for g in groups]

        self.g.assert_true(len(groups) > 0,
                           "Energy tab has module groups (%d found)"
                           % len(groups))

        # Verify groups are module names, not op_group names
        for name in group_names:
            is_module = name in self.ENERGY_MODULE_NAMES
            not_old_opgroup = name not in self.OP_GROUP_NAMES or name == "FUEL_CELLS"
            self.g.assert_true(is_module or not_old_opgroup,
                               "Group '%s' is a module name (not an op_group)"
                               % name)

        # Expect at least these modules for Earth
        self.g.assert_true("MODULE_SOLAR_ARRAYS" in group_names,
                           "MODULE_SOLAR_ARRAYS in Energy tab")
        self.g.assert_true("MODULE_COMBUSTION_POWER_PLANTS" in group_names,
                           "MODULE_COMBUSTION_POWER_PLANTS in Energy tab")

        # COMBUSTION_POWER_PLANTS should have child operations (7 fuel types)
        for g in groups:
            if g["title"] == "MODULE_COMBUSTION_POWER_PLANTS":
                n_ops = len(g.get("operations", []))
                self.g.assert_true(n_ops >= 2,
                                   "COMBUSTION_POWER_PLANTS has child ops (%d)"
                                   % n_ops)
                break

        # Single-op modules should have no child operations listed
        for g in groups:
            if g["title"] == "MODULE_SOLAR_ARRAYS":
                n_ops = len(g.get("operations", []))
                self.g.assert_true(n_ops == 0,
                                   "SOLAR_ARRAYS (single-op) has no child rows"
                                   " (%d found)" % n_ops)
                break

        # Use generic GUI inspection to verify ITabOperations node exists
        if self.g.has_cap("gui_inspection"):
            resp2 = self.client.call("find_nodes",
                                     {"script_class": "ITabOperations"})
            result2 = resp2.get("result", {})
            nodes = result2.get("nodes", [])
            self.g.assert_true(len(nodes) > 0,
                               "ITabOperations found via generic find_nodes"
                               " (%d)" % len(nodes))
            if nodes:
                path = nodes[0]["path"]
                resp3 = self.client.call("read_node_text",
                                         {"path": path, "max_labels": 50})
                result3 = resp3.get("result", {})
                entries = result3.get("entries", [])
                print("  Generic GUI inspection: %d entries at %s"
                      % (len(entries), path))
        else:
            print("  GUI inspection: not available (gui_inspection cap"
                  " missing)")

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
