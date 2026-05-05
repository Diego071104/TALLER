import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/services/ecg_socket_service.dart';

/// Owns the WebSocket connection lifecycle and exposes the latest
/// HelloMessage (sample rate, mode, available modes) to the UI.
class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider(this._socket) {
    _statusSub = _socket.statusStream.listen((s) {
      _status = s;
      notifyListeners();
    });
    _helloSub = _socket.hello.listen((h) {
      _sampleRate = h.sampleRate;
      _mode = h.mode;
      _availableModes = h.availableModes;
      notifyListeners();
    });
  }

  final EcgSocketService _socket;
  late final StreamSubscription<SocketStatus> _statusSub;
  late final StreamSubscription<HelloMessage> _helloSub;

  String _serverUrl = 'ws://localhost:8765';
  SocketStatus _status = SocketStatus.disconnected;
  int? _sampleRate;
  String? _mode;
  List<String> _availableModes = const [];

  String get serverUrl => _serverUrl;
  SocketStatus get status => _status;
  int? get sampleRate => _sampleRate;
  String? get mode => _mode;
  List<String> get availableModes => _availableModes;
  String? get lastError => _socket.lastError;
  EcgSocketService get socket => _socket;

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  Future<void> connect() async {
    try {
      await _socket.connect(_serverUrl);
    } catch (_) {
      // status stream already published failed; UI reads lastError.
    }
  }

  Future<void> disconnect() async {
    await _socket.disconnect();
  }

  void changeMode(String mode) {
    _socket.setMode(mode);
    _mode = mode;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub.cancel();
    _helloSub.cancel();
    super.dispose();
  }
}
