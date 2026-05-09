import 'dart:math' as math;

import '../data/models/beat.dart';
import '../data/models/ecg_sample.dart';

/// Lightweight local R-peak detector for a 250 Hz ECG stream.
///
/// It uses:
/// - local-maximum detection
/// - an adaptive threshold driven by recent signal envelope
/// - a refractory period to avoid double-counting the same QRS complex
class RPeakDetector {
  RPeakDetector({
    this.minThreshold = 0.18,
    this.thresholdMultiplier = 1.8,
    this.refractoryMs = 280,
    this.minRrMs = 300,
    this.maxRrMs = 2000,
  });

  final double minThreshold;
  final double thresholdMultiplier;
  final double refractoryMs;
  final double minRrMs;
  final double maxRrMs;

  double _envelope = 0.12;
  double? _prev2;
  double? _prev1;
  double? _prev1Ts;
  double? _lastBeatTs;

  Beat? add(EcgSample sample) {
    final value = sample.mv;
    final timestamp = sample.timestamp;
    _envelope = (_envelope * 0.995) + (value.abs() * 0.005);

    Beat? beat;
    if (_prev2 != null && _prev1 != null && _prev1Ts != null) {
      final threshold = math.max(minThreshold, _envelope * thresholdMultiplier);
      final isPeak = _prev1! > _prev2! && _prev1! >= value && _prev1! > threshold;
      final refractoryOk = _lastBeatTs == null ||
          ((_prev1Ts! - _lastBeatTs!) * 1000.0) >= refractoryMs;

      if (isPeak && refractoryOk) {
        if (_lastBeatTs != null) {
          final rrMs = (_prev1Ts! - _lastBeatTs!) * 1000.0;
          if (rrMs >= minRrMs && rrMs <= maxRrMs) {
            beat = Beat(
              timestamp: _prev1Ts!,
              rrMs: rrMs,
              instantBpm: 60000.0 / rrMs,
            );
          }
        }
        _lastBeatTs = _prev1Ts;
      }
    }

    _prev2 = _prev1;
    _prev1 = value;
    _prev1Ts = timestamp;
    return beat;
  }

  void reset() {
    _envelope = 0.12;
    _prev2 = null;
    _prev1 = null;
    _prev1Ts = null;
    _lastBeatTs = null;
  }
}
