"""Regression test for the disconnect race condition.

Reproduces the bug where a client disconnecting mid-broadcast caused
'RuntimeError: Set changed size during iteration' to crash the entire
server. After the fix in _broadcast (snapshot the client set before
iterating), this test passes — the server stays alive across many
connect/disconnect cycles.
"""
import asyncio
import json
import socket
import subprocess
import sys
import time

import websockets


PORT = 8799


def _wait_for_port(host: str, port: int, timeout: float = 5.0) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=0.5):
                return True
        except OSError:
            time.sleep(0.1)
    return False


async def _connect_and_drop(url: str, hold_s: float) -> bool:
    """Connect, receive a few messages, then close abruptly."""
    try:
        async with websockets.connect(url, open_timeout=2) as ws:
            received = 0
            deadline = asyncio.get_event_loop().time() + hold_s
            while asyncio.get_event_loop().time() < deadline:
                try:
                    msg = await asyncio.wait_for(ws.recv(), timeout=0.5)
                    json.loads(msg)
                    received += 1
                except asyncio.TimeoutError:
                    pass
            return received > 5
    except Exception:
        return False


async def main() -> int:
    proc = subprocess.Popen(
        [sys.executable, "ecg_server.py", "--port", str(PORT), "--log-level", "WARNING"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    try:
        if not _wait_for_port("127.0.0.1", PORT, timeout=5):
            print("FAIL: server never started")
            return 1

        url = f"ws://127.0.0.1:{PORT}"
        cycles = 5
        per_cycle_received = []
        for i in range(cycles):
            ok = await _connect_and_drop(url, hold_s=0.6)
            per_cycle_received.append(ok)
            if proc.poll() is not None:
                stdout = proc.stdout.read() if proc.stdout else ""
                print(f"FAIL: server died after cycle {i+1}")
                print(f"--- server stdout ---\n{stdout}")
                return 1
            await asyncio.sleep(0.1)

        if not all(per_cycle_received):
            print(f"FAIL: not all cycles received samples: {per_cycle_received}")
            return 1

        if proc.poll() is not None:
            print("FAIL: server died at the end")
            return 1

        print(f"PASS: {cycles} connect/disconnect cycles survived; server still alive")
        return 0
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
