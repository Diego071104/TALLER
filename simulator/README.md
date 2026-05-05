# ECG Simulator

WebSocket service that emulates an ECG sensor for the Flutter app. Replaces the Arduino + HC-06 Bluetooth pulse setup originally suggested in the deliverable, while keeping the upstream signal contract identical to what real hardware would produce.

## Why a simulator instead of hardware

We do not have access to an Arduino + ECG sensor for this delivery. The simulator generates synthetic but **physiologically realistic** PQRST waveforms at the same sample rate a real sensor would (250 Hz) and exposes them over a transport (WebSocket) that is functionally interchangeable with BLE for the purposes of the application logic — same JSON shape, same streaming cadence, same concept of beat events.

## Install

Requires Python 3.11+.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
python ecg_server.py --mode normal --port 8765 --rate 250
```

Flags:

| Flag | Default | Notes |
|------|---------|-------|
| `--host` | `0.0.0.0` | Bind address. Defaults to all interfaces so phones on the same WiFi can connect. |
| `--port` | `8765` | WebSocket port. |
| `--mode` | `normal` | One of `normal`, `tachycardia`, `bradycardia`, `arrhythmia`, `exercise`. |
| `--rate` | `250` | Samples per second. |
| `--log-level` | `INFO` | Standard Python logging levels. |

The mode can also be changed live from the Flutter app (it sends a `set_mode` message over the open WebSocket).

## Wire protocol

### Server → Client

On connect:

```json
{ "type": "hello", "sample_rate": 250, "mode": "normal",
  "modes": ["normal", "tachycardia", "bradycardia", "arrhythmia", "exercise"] }
```

Then continuously:

```json
{ "type": "ecg_sample", "ts": 1746205823.412, "mv": -0.12 }
```

And every detected R peak:

```json
{ "type": "beat", "ts": 1746205823.892, "rr_ms": 856, "instant_bpm": 70.1 }
```

### Client → Server

```json
{ "type": "set_mode", "mode": "exercise" }
```

## Modes

| Mode | Mean BPM | Pattern |
|------|---------|---------|
| `normal` | 70 | Sinusoidal drift around 70 BPM |
| `tachycardia` | 125 | High rate, regular |
| `bradycardia` | 48 | Low rate, regular |
| `arrhythmia` | 75 | Periodic premature beats with compensatory pauses |
| `exercise` | 70 → 150 | Linear ramp over 60 s, then plateau |

## Architecture notes

- **`ecg_synth.py`** holds all waveform logic. `EcgGenerator` is a stateful sample generator: each call to `next_sample()` advances the cardiac cycle by `1 / sample_rate` seconds and returns one millivolt value. R peaks are detected at generation time (no signal-processing detector needed) and surfaced as `BeatEvent`s.
- **`ecg_server.py`** is a thin asyncio + websockets layer that wraps the generator. It owns the broadcast loop, the connected-client set, and the inbound message router.

## Testing the simulator standalone

A quick stdout dump:

```bash
python -c "
from ecg_synth import EcgGenerator
gen = EcgGenerator(mode='normal')
for i in range(10):
    mv, beat = gen.next_sample()
    print(f'{mv:+.4f}', '<-- BEAT' if beat else '')
"
```

Or a self-test client:

```bash
pip install websockets
python -c "
import asyncio, json, websockets
async def main():
    async with websockets.connect('ws://localhost:8765') as ws:
        for _ in range(20):
            print(await ws.recv())
asyncio.run(main())
"
```
