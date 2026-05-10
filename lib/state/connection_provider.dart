import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/services/ecg_signal_service.dart';

class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider(this._signal) {
    _status = _signal.status;
    _deviceLabel = _signal.deviceLabel;
    _statusSub = _signal.statusStream.listen((s) {
      _status = s;
      _deviceLabel = _signal.deviceLabel;
      notifyListeners();
    });
  }

  final EcgSignalService _signal;
  late final StreamSubscription<SignalConnectionStatus> _statusSub;

  SignalConnectionStatus _status = SignalConnectionStatus.disconnected;
  String? _deviceLabel;

  SignalConnectionStatus get status => _status;
  int get sampleRate => _signal.sampleRate;
  bool get isSupported => _signal.isSupported;
  String? get deviceLabel => _deviceLabel;
  String? get lastError => _signal.lastError;
  EcgSignalService get signal => _signal;

  Future<void> connect() async {
    try {
      await _signal.connect();
      _deviceLabel = _signal.deviceLabel;
      notifyListeners();
    } catch (_) {
      // UI reads the published status and lastError.
    }
  }

  Future<void> disconnect() async {
    await _signal.disconnect();
  }

  @override
  void dispose() {
    _statusSub.cancel();
    super.dispose();
  }
}
