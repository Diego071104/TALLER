"""ECG signal synthesizer.

Generates a realistic ECG waveform sample-by-sample using a sum of Gaussian
bumps for the PQRST morphology of one cardiac cycle. The generator is
stateful: each call to next_sample advances the cardiac cycle by 1/sample_rate
seconds and returns one millivolt value.

The generator also reports beat events at the moment an R peak is produced,
exposing the instantaneous BPM derived from the R-R interval since the
previous R peak.

Supported modes: normal, tachycardia, bradycardia, arrhythmia, exercise.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from typing import Optional

# PQRST template: each (center_phase, sigma, amplitude_mv).
# Phase is normalized to one beat (0.0 -> 1.0). Amplitudes in millivolts.
_PQRST = [
    (0.18, 0.025, 0.12),   # P wave  (atrial depolarization)
    (0.30, 0.012, -0.15),  # Q wave
    (0.32, 0.008, 1.10),   # R wave  (sharp positive spike)
    (0.34, 0.012, -0.25),  # S wave
    (0.52, 0.060, 0.30),   # T wave  (ventricular repolarization)
]
_R_PEAK_PHASE = 0.32

VALID_MODES = ("normal", "tachycardia", "bradycardia", "arrhythmia", "exercise")


@dataclass
class BeatEvent:
    rr_ms: float
    instant_bpm: float


def _gauss(phase: float, center: float, sigma: float) -> float:
    return math.exp(-((phase - center) ** 2) / (2.0 * sigma * sigma))


class EcgGenerator:
    def __init__(self, mode: str = "normal", sample_rate: int = 250) -> None:
        self.sample_rate = sample_rate
        self._dt = 1.0 / sample_rate
        self._t = 0.0
        self._beat_phase = 0.0
        self._last_r_time: Optional[float] = None
        self._beat_count = 0
        self._next_rr_multiplier = 1.0  # used by arrhythmia mode
        self.mode = "normal"
        self.set_mode(mode)

    def set_mode(self, mode: str) -> None:
        if mode not in VALID_MODES:
            raise ValueError(f"unknown mode: {mode}; valid: {VALID_MODES}")
        self.mode = mode

    def _target_bpm(self) -> float:
        t = self._t
        if self.mode == "normal":
            return 70.0 + 5.0 * math.sin(t * 0.10)
        if self.mode == "tachycardia":
            return 125.0 + 6.0 * math.sin(t * 0.20)
        if self.mode == "bradycardia":
            return 48.0 + 3.0 * math.sin(t * 0.10)
        if self.mode == "exercise":
            return min(150.0, 70.0 + 1.3 * t)
        if self.mode == "arrhythmia":
            return 75.0 + 4.0 * math.sin(t * 0.15)
        raise RuntimeError(f"unhandled mode: {self.mode}")

    def _pqrst_amplitude(self, phase: float) -> float:
        amp = 0.0
        for center, sigma, a in _PQRST:
            amp += a * _gauss(phase, center, sigma)
        return amp

    def _add_noise(self, sample: float) -> float:
        sample += random.gauss(0.0, 0.015)                       # white noise
        sample += 0.05 * math.sin(2.0 * math.pi * 0.3 * self._t)  # baseline wander
        sample += 0.01 * math.sin(2.0 * math.pi * 60.0 * self._t) # power-line 60 Hz
        return sample

    def next_sample(self) -> tuple[float, Optional[BeatEvent]]:
        bpm = self._target_bpm()
        beat_duration = (60.0 / bpm) * self._next_rr_multiplier

        amplitude = self._pqrst_amplitude(self._beat_phase)
        amplitude = self._add_noise(amplitude)

        prev_phase = self._beat_phase
        delta = self._dt / beat_duration
        new_phase = prev_phase + delta

        beat: Optional[BeatEvent] = None
        if prev_phase < _R_PEAK_PHASE <= new_phase:
            self._beat_count += 1
            if self._last_r_time is None:
                rr_ms = 60_000.0 / bpm
            else:
                rr_ms = (self._t - self._last_r_time) * 1000.0
            instant_bpm = 60_000.0 / rr_ms if rr_ms > 0 else bpm
            beat = BeatEvent(rr_ms=rr_ms, instant_bpm=instant_bpm)
            self._last_r_time = self._t

            if self.mode == "arrhythmia":
                if self._beat_count % 5 == 0:
                    self._next_rr_multiplier = 0.65    # premature beat
                elif self._beat_count % 5 == 1:
                    self._next_rr_multiplier = 1.35    # compensatory pause
                else:
                    self._next_rr_multiplier = 1.0 + random.uniform(-0.04, 0.04)
            else:
                self._next_rr_multiplier = 1.0

        if new_phase >= 1.0:
            new_phase -= 1.0
        self._beat_phase = new_phase
        self._t += self._dt
        return amplitude, beat
