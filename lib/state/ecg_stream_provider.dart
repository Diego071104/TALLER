import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/models/beat.dart';
import '../data/models/ecg_sample.dart';
import '../data/services/ecg_socket_service.dart';

/// Holds a fixed-length ring buffer of recent ECG samples plus the latest
/// beats. Notifies listeners on every incoming sample so charts can repaint
/// in real time.
///
/// Visible window defaults to 1500 samples = 6.0 s at 250 Hz, matching the
/// span typically shown in clinical strips.
class EcgStreamProvider extends ChangeNotifier {
  EcgStreamProvider(
    this._socket, {
    this.windowSize = 1500,
    this.beatHistory = 60,
    this.notifyEverySamples = 4,
  }) {
    _sampleSub = _socket.samples.listen(_onSample);
    _beatSub = _socket.beats.listen(_onBeat);
  }

  final EcgSocketService _socket;
  final int windowSize;
  final int beatHistory;

  /// At 250 Hz, notifying on every sample would force ~250 rebuilds/sec.
  /// Notifying every 4th sample yields ~62 Hz UI updates — visually smooth
  /// while leaving headroom for the chart layer.
  final int notifyEverySamples;
  int _sinceNotify = 0;

  late final StreamSubscription<EcgSample> _sampleSub;
  late final StreamSubscription<Beat> _beatSub;

  final Queue<EcgSample> _samples = Queue<EcgSample>();
  final Queue<Beat> _beats = Queue<Beat>();
  Beat? _lastBeat;

  Iterable<EcgSample> get samples => _samples;
  Iterable<Beat> get recentBeats => _beats;
  Beat? get lastBeat => _lastBeat;
  int get sampleCount => _samples.length;

  /// Average BPM over the last 6 beats — smoother than instant_bpm and
  /// what the UI displays as the headline number.
  double? get smoothedBpm {
    if (_beats.isEmpty) return null;
    final n = _beats.length < 6 ? _beats.length : 6;
    final tail = _beats.toList().sublist(_beats.length - n);
    final sum = tail.fold<double>(0, (acc, b) => acc + b.instantBpm);
    return sum / n;
  }

  /// Heart rate variability (RMSSD) over recent RR intervals — clinical
  /// indicator that flips high during arrhythmia / stress.
  double? get rmssdMs {
    if (_beats.length < 4) return null;
    final tail = _beats.toList();
    double sumSquares = 0;
    int count = 0;
    for (var i = 1; i < tail.length; i++) {
      final diff = tail[i].rrMs - tail[i - 1].rrMs;
      sumSquares += diff * diff;
      count++;
    }
    if (count == 0) return null;
    return _sqrt(sumSquares / count);
  }

  void _onSample(EcgSample s) {
    _samples.addLast(s);
    while (_samples.length > windowSize) {
      _samples.removeFirst();
    }
    _sinceNotify++;
    if (_sinceNotify >= notifyEverySamples) {
      _sinceNotify = 0;
      notifyListeners();
    }
  }

  void _onBeat(Beat b) {
    _beats.addLast(b);
    while (_beats.length > beatHistory) {
      _beats.removeFirst();
    }
    _lastBeat = b;
    notifyListeners();
  }

  void clear() {
    _samples.clear();
    _beats.clear();
    _lastBeat = null;
    notifyListeners();
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var guess = x;
    for (var i = 0; i < 10; i++) {
      guess = 0.5 * (guess + x / guess);
    }
    return guess;
  }

  @override
  void dispose() {
    _sampleSub.cancel();
    _beatSub.cancel();
    super.dispose();
  }
}
