#!/usr/bin/env python3
"""GDScript warning checker using Godot's Language Server Protocol.

Launches the Godot editor with its LSP server, opens GDScript files, and
collects diagnostics (warnings and errors). Prints results and exits with
status 0 (clean), 1 (warnings found), or 2 (connection/launch failure).

Usage:
    python check_warnings.py                       # all public/ .gd files
    python check_warnings.py path/to/file.gd       # specific files
    python check_warnings.py --include-nonpublic   # also check nonpublic/
    python check_warnings.py --godot PATH          # override auto-detect
"""

import argparse
import glob
import json
import os
import re
import socket
import subprocess
import sys
import time
from pathlib import Path


# ---------------------------------------------------------------------------
# Godot executable discovery
# ---------------------------------------------------------------------------

def find_godot_executable(search_dir):
    """Find the most recent Godot *_console.exe in search_dir by version."""
    pattern = os.path.join(search_dir, "Godot_v*_console.exe")
    candidates = glob.glob(pattern)
    if not candidates:
        return None

    def version_key(path):
        name = os.path.basename(path)
        m = re.search(r"v(\d+)\.(\d+)(?:\.(\d+))?", name)
        if m:
            return (int(m.group(1)), int(m.group(2)), int(m.group(3) or 0))
        return (0, 0, 0)

    candidates.sort(key=version_key)
    return candidates[-1]


# ---------------------------------------------------------------------------
# Minimal LSP client over TCP (Content-Length framing)
# ---------------------------------------------------------------------------

class LSPClient:
    """Minimal Language Server Protocol client over TCP."""

    def __init__(self, host="127.0.0.1", port=6005, timeout=10.0):
        self.host = host
        self.port = port
        self.timeout = timeout
        self._sock = None
        self._buffer = b""
        self._request_id = 0

    def connect(self, retries=30, delay=1.0):
        """Retry TCP connection until the LSP server is ready."""
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
            "Could not connect to LSP at %s:%d after %d attempts"
            % (self.host, self.port, retries)
        )

    def send_request(self, method, params=None):
        self._request_id += 1
        msg = {"jsonrpc": "2.0", "id": self._request_id, "method": method}
        if params is not None:
            msg["params"] = params
        self._send(msg)
        return self._request_id

    def send_notification(self, method, params=None):
        msg = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        self._send(msg)

    def recv_messages(self, timeout=5.0):
        """Receive all available LSP messages within timeout."""
        messages = []
        deadline = time.time() + timeout
        while time.time() < deadline:
            msg = self._try_recv(max(0.1, deadline - time.time()))
            if msg is None:
                break
            messages.append(msg)
        return messages

    def collect_diagnostics(self, quiet_timeout=3.0, max_wait=30.0):
        """Collect publishDiagnostics until no new messages for quiet_timeout."""
        diagnostics = {}  # uri -> list of diagnostics
        other_messages = []
        last_msg_time = time.time()
        deadline = time.time() + max_wait

        while time.time() < deadline:
            remaining_quiet = quiet_timeout - (time.time() - last_msg_time)
            remaining_total = deadline - time.time()
            wait = max(0.1, min(remaining_quiet, remaining_total))

            msg = self._try_recv(wait)
            if msg is None:
                if time.time() - last_msg_time >= quiet_timeout:
                    break
                continue

            last_msg_time = time.time()
            if msg.get("method") == "textDocument/publishDiagnostics":
                uri = msg["params"]["uri"]
                diags = msg["params"].get("diagnostics", [])
                diagnostics[uri] = diags
            else:
                other_messages.append(msg)

        return diagnostics

    def close(self):
        if self._sock:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None

    def _send(self, msg):
        body = json.dumps(msg).encode("utf-8")
        header = ("Content-Length: %d\r\n\r\n" % len(body)).encode("ascii")
        self._sock.sendall(header + body)

    def _try_recv(self, timeout):
        """Try to receive one LSP message within timeout. Returns None on timeout."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            # Check if we have a complete message in buffer
            msg = self._try_parse_buffer()
            if msg is not None:
                return msg
            # Read more data
            remaining = max(0.01, deadline - time.time())
            self._sock.settimeout(remaining)
            try:
                chunk = self._sock.recv(8192)
                if not chunk:
                    return None
                self._buffer += chunk
            except socket.timeout:
                return None
        return None

    def _try_parse_buffer(self):
        """Try to parse a complete Content-Length framed message from buffer."""
        header_end = self._buffer.find(b"\r\n\r\n")
        if header_end < 0:
            return None
        header = self._buffer[:header_end].decode("ascii")
        content_length = 0
        for line in header.split("\r\n"):
            if line.lower().startswith("content-length:"):
                content_length = int(line.split(":")[1].strip())
        body_start = header_end + 4
        if len(self._buffer) < body_start + content_length:
            return None  # incomplete body
        body = self._buffer[body_start : body_start + content_length]
        self._buffer = self._buffer[body_start + content_length :]
        return json.loads(body.decode("utf-8"))


# ---------------------------------------------------------------------------
# Warning checker
# ---------------------------------------------------------------------------

class WarningChecker:
    """Orchestrates Godot launch, LSP connection, and diagnostic collection."""

    SEVERITY_MAP = {1: "ERROR", 2: "WARNING", 3: "INFO", 4: "HINT"}

    def __init__(self, godot_path, project_path, lsp_port=6005):
        self.godot_path = godot_path
        self.project_path = os.path.abspath(project_path)
        self.lsp_port = lsp_port
        self.godot_proc = None

    def launch_godot(self):
        """Start Godot editor with LSP server."""
        cmd = [self.godot_path, "--editor", "--path", self.project_path,
               "--lsp-port", str(self.lsp_port)]
        self.godot_proc = subprocess.Popen(
            cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        return self.godot_proc

    def kill_godot(self):
        if self.godot_proc:
            try:
                self.godot_proc.kill()
                self.godot_proc.wait(timeout=10)
            except (OSError, subprocess.TimeoutExpired):
                pass

    def file_to_uri(self, filepath):
        """Convert a filesystem path to a file:/// URI."""
        return Path(os.path.abspath(filepath)).as_uri()

    def uri_to_relpath(self, uri):
        """Convert a file URI back to a project-relative path."""
        # Decode percent-encoded characters
        from urllib.parse import unquote
        path = unquote(uri)
        if path.startswith("file:///"):
            path = path[8:]  # strip file:///
        # Normalize to forward slashes
        path = path.replace("\\", "/")
        proj = self.project_path.replace("\\", "/")
        if not proj.endswith("/"):
            proj += "/"
        # Case-insensitive prefix match on Windows
        if path.lower().startswith(proj.lower()):
            return path[len(proj):]
        return path

    def check_files(self, file_paths):
        """Open files via LSP, collect diagnostics, return results."""
        client = LSPClient(port=self.lsp_port)

        print("Connecting to LSP on port %d..." % self.lsp_port)
        client.connect(retries=30, delay=1.0)
        print("Connected.")

        try:
            # Initialize
            client.send_request("initialize", {
                "processId": None,
                "rootUri": Path(self.project_path).as_uri(),
                "capabilities": {
                    "textDocument": {
                        "publishDiagnostics": {"relatedInformation": True}
                    }
                }
            })
            # Drain init response
            client.recv_messages(timeout=5.0)

            client.send_notification("initialized", {})
            time.sleep(1)

            # Batch open all files
            print("Opening %d GDScript file(s)..." % len(file_paths))
            for i, fp in enumerate(file_paths):
                uri = self.file_to_uri(fp)
                with open(fp, "r", encoding="utf-8") as f:
                    text = f.read()
                client.send_notification("textDocument/didOpen", {
                    "textDocument": {
                        "uri": uri,
                        "languageId": "gdscript",
                        "version": 1,
                        "text": text,
                    }
                })

            # Collect diagnostics
            print("Collecting diagnostics...")
            diagnostics = client.collect_diagnostics(quiet_timeout=3.0,
                                                      max_wait=60.0)
            return diagnostics

        finally:
            client.close()

    def format_results(self, diagnostics, opened_uris=None):
        """Format diagnostics for display. Returns (output_lines, warning_count)."""
        lines = []
        total_warnings = 0

        for uri, diags in sorted(diagnostics.items()):
            if not diags:
                continue
            relpath = self.uri_to_relpath(uri)
            for d in sorted(diags, key=lambda x: x["range"]["start"]["line"]):
                line_num = d["range"]["start"]["line"] + 1
                severity = self.SEVERITY_MAP.get(d.get("severity", 0), "?")
                message = d.get("message", "")
                # Extract named code from message, e.g., "(UNTYPED_DECLARATION):"
                code_match = re.search(r"\(([A-Z_]+)\)", message)
                code = code_match.group(1) if code_match else str(d.get("code", ""))
                lines.append("%s:%d: %s %s - %s"
                             % (relpath, line_num, severity, code, message))
                if severity in ("WARNING", "ERROR"):
                    total_warnings += 1

        return lines, total_warnings


# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------

def find_gd_files(project_path, include_nonpublic=False):
    """Find all .gd files in public/ (and optionally nonpublic/)."""
    files = []
    public_dir = os.path.join(project_path, "public")
    if os.path.isdir(public_dir):
        for root, dirs, filenames in os.walk(public_dir):
            for fn in filenames:
                if fn.endswith(".gd"):
                    files.append(os.path.join(root, fn))

    if include_nonpublic:
        np_dir = os.path.join(project_path, "nonpublic")
        if os.path.isdir(np_dir):
            for root, dirs, filenames in os.walk(np_dir):
                for fn in filenames:
                    if fn.endswith(".gd"):
                        files.append(os.path.join(root, fn))

    return sorted(files)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Check GDScript warnings via Godot LSP.")
    parser.add_argument("files", nargs="*",
                        help="Specific .gd files to check (default: all in public/)")
    parser.add_argument("--godot", default=None,
                        help="Path to Godot executable (auto-detected from ../)")
    parser.add_argument("--project", default=".",
                        help="Path to project directory (default: .)")
    parser.add_argument("--lsp-port", type=int, default=6005,
                        help="LSP server port (default: 6005)")
    parser.add_argument("--include-nonpublic", action="store_true",
                        help="Also check nonpublic/ directory")
    args = parser.parse_args()

    project_path = os.path.abspath(args.project)

    # Find Godot executable
    if args.godot:
        godot = args.godot
    else:
        parent_dir = os.path.join(project_path, "..")
        godot = find_godot_executable(parent_dir)
        if not godot:
            print("ERROR: No Godot console executable found in %s"
                  % os.path.abspath(parent_dir))
            print("Use --godot PATH to specify manually.")
            sys.exit(2)

    if not os.path.isfile(godot):
        print("ERROR: Godot executable not found: %s" % godot)
        sys.exit(2)

    # Determine files to check
    if args.files:
        file_paths = [os.path.abspath(f) for f in args.files]
        for fp in file_paths:
            if not os.path.isfile(fp):
                print("ERROR: File not found: %s" % fp)
                sys.exit(2)
    else:
        file_paths = find_gd_files(project_path,
                                    include_nonpublic=args.include_nonpublic)

    if not file_paths:
        print("No .gd files found to check.")
        sys.exit(0)

    checker = WarningChecker(godot, project_path, args.lsp_port)

    print("Using Godot: %s" % os.path.basename(godot))
    print("Launching Godot editor with LSP on port %d..." % args.lsp_port)
    checker.launch_godot()

    try:
        diagnostics = checker.check_files(file_paths)
        output_lines, warning_count = checker.format_results(diagnostics)

        print()
        if output_lines:
            for line in output_lines:
                print(line)
            print()

        n_files_with_warnings = sum(
            1 for diags in diagnostics.values() if diags)
        print("=== %d warning(s) in %d file(s) (%d file(s) checked) ==="
              % (warning_count, n_files_with_warnings, len(file_paths)))

        sys.exit(1 if warning_count > 0 else 0)

    except ConnectionError as e:
        print("ERROR: %s" % e)
        sys.exit(2)
    except Exception as e:
        print("ERROR: %s" % e)
        import traceback
        traceback.print_exc()
        sys.exit(2)
    finally:
        checker.kill_godot()


if __name__ == "__main__":
    main()
