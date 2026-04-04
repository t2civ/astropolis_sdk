#!/usr/bin/env python3
"""Astropolis Interface test runner.

Connects to the ivoyager_assistant TCP server and runs assertions against
Interface development statistics for PLANET_EARTH and JOIN_OFFWORLD.

Usage:
    python test_interfaces.py                  # game already running
    python test_interfaces.py --launch         # start Godot automatically
    python test_interfaces.py --host HOST      # custom host (default: 127.0.0.1)
    python test_interfaces.py --port PORT      # custom port (default: 29071)
"""

import argparse
import json
import socket
import subprocess
import sys
import time


class AssistantClient:
    """TCP client for the ivoyager_assistant JSON-RPC server."""

    def __init__(self, host: str = "127.0.0.1", port: int = 29071, timeout: float = 10.0):
        self.host = host
        self.port = port
        self.timeout = timeout
        self._sock: socket.socket | None = None
        self._buffer = b""
        self._request_id = 0

    def connect(self, retries: int = 30, delay: float = 2.0) -> None:
        for attempt in range(retries):
            try:
                self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self._sock.settimeout(self.timeout)
                self._sock.connect((self.host, self.port))
                return
            except (ConnectionRefusedError, OSError):
                self._sock = None
                if attempt < retries - 1:
                    time.sleep(delay)
        raise ConnectionError(
            f"Could not connect to {self.host}:{self.port} after {retries} attempts"
        )

    def close(self) -> None:
        if self._sock:
            self._sock.close()
            self._sock = None

    def call(self, method: str, params: dict | None = None) -> dict:
        self._request_id += 1
        request = {"id": self._request_id, "method": method}
        if params:
            request["params"] = params
        line = json.dumps(request) + "\n"
        self._sock.sendall(line.encode("utf-8"))
        return self._recv_response()

    def _recv_response(self) -> dict:
        while True:
            newline_pos = self._buffer.find(b"\n")
            if newline_pos >= 0:
                line = self._buffer[:newline_pos]
                self._buffer = self._buffer[newline_pos + 1:]
                return json.loads(line.decode("utf-8"))
            chunk = self._sock.recv(4096)
            if not chunk:
                raise ConnectionError("Server closed connection")
            self._buffer += chunk


class TestRunner:
    """Runs interface tests against a live Astropolis instance."""

    def __init__(self, client: AssistantClient):
        self.client = client
        self.passed = 0
        self.failed = 0
        self.errors: list[str] = []

    def assert_true(self, condition: bool, message: str) -> None:
        if condition:
            self.passed += 1
            print(f"  PASS: {message}")
        else:
            self.failed += 1
            self.errors.append(message)
            print(f"  FAIL: {message}")

    def assert_gt(self, value: float, threshold: float, name: str) -> None:
        self.assert_true(
            value > threshold,
            f"{name} = {value} (expected > {threshold})"
        )

    def assert_eq(self, value, expected, name: str) -> None:
        self.assert_true(
            value == expected,
            f"{name} = {value} (expected {expected})"
        )

    def run_all(self, economy: bool = False) -> bool:
        print("\n=== Astropolis Interface Tests ===\n")

        self.test_connection()
        self.test_wait_for_started()
        self.test_list_interfaces()
        self.test_interface_info()
        self.test_instant_development_stats()
        self.test_short_time_stats()
        if economy:
            self.test_economy_stats()
        else:
            print("[test_economy_stats] SKIPPED (use --economy to enable)")

        print(f"\n=== Results: {self.passed} passed, {self.failed} failed ===")
        if self.errors:
            print("\nFailures:")
            for err in self.errors:
                print(f"  - {err}")
        return self.failed == 0

    def test_connection(self) -> None:
        print("[test_connection]")
        resp = self.client.call("get_project_info")
        result = resp.get("result", {})
        caps = result.get("capabilities", [])
        self.assert_true(
            "astropolis_interfaces" in caps,
            "AstropolisTestSuite capability registered"
        )

    def test_wait_for_started(self) -> None:
        print("[test_wait_for_started]")
        # Check if game needs start_game call (splash screen / main menu)
        resp = self.client.call("get_project_info")
        result = resp.get("result", {})
        if result.get("wait_for_start", False) and not result.get("started", False):
            print("  Calling start_game...")
            self.client.call("start_game")
        for _ in range(60):
            resp = self.client.call("get_state")
            result = resp.get("result", {})
            if result.get("started", False):
                self.assert_true(True, "Simulator started")
                return
            time.sleep(1.0)
        self.assert_true(False, "Simulator started (timed out after 60s)")

    def test_list_interfaces(self) -> None:
        print("[test_list_interfaces]")
        resp = self.client.call("list_interfaces", {"has_development": True})
        result = resp.get("result", {})
        interfaces = result.get("interfaces", [])
        names = [i["name"] for i in interfaces]
        self.assert_true("PLANET_EARTH" in names, "PLANET_EARTH in interface list")
        self.assert_true("JOIN_OFFWORLD" in names, "JOIN_OFFWORLD in interface list")
        self.assert_true(len(interfaces) > 2, f"Multiple interfaces with development ({len(interfaces)} found)")

    def test_interface_info(self) -> None:
        print("[test_interface_info]")
        for name in ("PLANET_EARTH", "JOIN_OFFWORLD"):
            resp = self.client.call("get_interface_info", {"name": name})
            result = resp.get("result", {})
            self.assert_true(
                "error" not in resp,
                f"{name} interface found"
            )
            self.assert_true(
                result.get("has_development", False),
                f"{name} has development"
            )
            self.assert_true(
                result.get("has_operations", False),
                f"{name} has operations"
            )
            self.assert_true(
                result.get("has_population", False),
                f"{name} has population"
            )
            self.assert_true(
                result.get("has_biome", False),
                f"{name} has biome"
            )

    def test_instant_development_stats(self) -> None:
        print("[test_instant_development_stats]")
        for name in ("PLANET_EARTH", "JOIN_OFFWORLD"):
            resp = self.client.call("get_development_stats", {"name": name})
            result = resp.get("result", {})
            self.assert_true("error" not in resp, f"{name} development stats returned")
            # These are positive immediately after sim start
            self.assert_gt(result.get("population", 0), 0, f"{name}.population")
            self.assert_gt(result.get("constructions", 0), 0, f"{name}.constructions")
            self.assert_gt(result.get("information", 0), 0, f"{name}.information")
            self.assert_gt(result.get("biomass", 0), 0, f"{name}.biomass")
            self.assert_gt(result.get("biodiversity", 0), 0, f"{name}.biodiversity")
            # PLANET_EARTH has bioproductivity; JOIN_OFFWORLD (spacecraft) does not
            if name == "PLANET_EARTH":
                self.assert_gt(result.get("bioproductivity", 0), 0, f"{name}.bioproductivity")
            else:
                self.assert_eq(result.get("bioproductivity", -1), 0.0,
                               f"{name}.bioproductivity (spacecraft have no biome)")
            # Power and manufacturing need a simulation week to populate
            # Economy needs ~1 game year (LFQ averaging)
            # Computation is not yet populated
            self.assert_eq(result.get("computation", -1), 0.0,
                           f"{name}.computation (not yet populated)")

    def _advance_time_days(self, days: int, speed_index: int = 6) -> bool:
        """Advance simulation by approximately `days` game-days. Returns True on success."""
        resp = self.client.call("get_time")
        start_time = resp.get("result", {}).get("time", 0)
        target_time = start_time + days * 86400  # seconds per day

        self.client.call("set_pause", {"paused": False})
        self.client.call("set_speed", {"index": speed_index})

        for attempt in range(60):
            resp = self.client.call("get_time")
            current_time = resp.get("result", {}).get("time", 0)
            if current_time >= target_time:
                self.client.call("set_speed", {"index": 0})
                elapsed_days = (current_time - start_time) / 86400
                print(f"  Advanced {elapsed_days:.0f} game-days in {attempt + 1} polls")
                return True
            time.sleep(0.5)

        self.client.call("set_speed", {"index": 0})
        return False

    def test_short_time_stats(self) -> None:
        """Stats that need ~1 game week: power, manufacturing."""
        print("[test_short_time_stats]")
        if not self._advance_time_days(10):
            self.assert_true(False, "Time advanced 10 days (timed out)")
            return

        for name in ("PLANET_EARTH",):
            resp = self.client.call("get_development_stats", {"name": name})
            result = resp.get("result", {})
            self.assert_gt(result.get("power", 0), 0,
                           f"{name}.power (after ~10 days)")
            self.assert_gt(result.get("manufacturing", 0), 0,
                           f"{name}.manufacturing (after ~10 days)")

    def test_economy_stats(self) -> None:
        """Economy needs ~1 game year of LFQ data. Use --economy flag to run."""
        print("[test_economy_stats]")
        resp = self.client.call("get_time")
        date = resp.get("result", {}).get("date", [2025, 1, 1])
        print(f"  Current date: {date}")

        # Advance ~2 years for full LFQ coverage
        if not self._advance_time_days(730):
            self.assert_true(False, "Time advanced ~2 years (timed out)")
            return

        resp = self.client.call("get_development_stats", {"name": "PLANET_EARTH"})
        result = resp.get("result", {})
        self.assert_gt(result.get("economy", 0), 0,
                       "PLANET_EARTH.economy (after ~2 years)")

        # JOIN_OFFWORLD (spacecraft) has no meaningful economy
        resp = self.client.call("get_development_stats", {"name": "JOIN_OFFWORLD"})
        result = resp.get("result", {})
        self.assert_eq(result.get("economy", -1), 0.0,
                       "JOIN_OFFWORLD.economy (spacecraft have no gross output)")


def main() -> None:
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
    args = parser.parse_args()

    godot_proc = None
    if args.launch:
        godot = args.godot or "../Godot_v4.6.2-stable_win64_console.exe"
        project = args.project or "."
        print(f"Launching Godot: {godot} --path {project}")
        godot_proc = subprocess.Popen([godot, "--path", project])

    client = AssistantClient(host=args.host, port=args.port)
    try:
        print(f"Connecting to {args.host}:{args.port}...")
        client.connect()
        print("Connected!")

        runner = TestRunner(client)
        success = runner.run_all(economy=args.economy)

        # Quit the game
        print("\nSending quit...")
        client.call("quit", {"force": True})
    except Exception as e:
        print(f"\nERROR: {e}")
        success = False
    finally:
        client.close()
        if godot_proc:
            godot_proc.wait(timeout=10)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
