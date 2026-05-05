import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../models/beat.dart';
import '../models/ecg_sample.dart';

enum SocketStatus { disconnected, connecting, connected, failed }

class HelloMessage {
  final int sampleRate;
  final String mode;
  final List<String> availableModes;

  const HelloMessage({
    required this.sampleRate,
    required this.mode,
    required this.availableModes,
  });

  factory HelloMessage.fromJson(Map<String, dynamic> json) => HelloMessage(
        sampleRate: (json['sample_rate'] as num).toInt(),
        mode: json['mode'] as String,
        availableModes: (json['modes'] as List).cast<String>(),
      );
}

/// WebSocket bridge to the Python ECG simulator.
///
/// Exposes three streams (samples, beats, hello) and a status notifier.
/// Reconnects must be triggered explicitly by calling connect again — the
/// service does not auto-retry to keep failure modes obvious during demos.
class EcgSocketService {
  final _samplesController = StreamController<EcgSample>.broadcast();
  final _beatsController = StreamController<Beat>.broadcast();
  final _helloController = StreamController<HelloMessage>.broadcast();
  final _statusController = StreamController<SocketStatus>.broadcast();

  WebSocketChannel? _channel;
  SocketStatus _status = SocketStatus.disconnected;
  String? _lastError;

  Stream<EcgSample> get samples => _samplesController.stream;
  Stream<Beat> get beats => _beatsController.stream;
  Stream<HelloMessage> get hello => _helloController.stream;
  Stream<SocketStatus> get statusStream => _statusController.stream;

  SocketStatus get status => _status;
  String? get lastError => _lastError;

  Future<void> connect(String url) async {
    await disconnect();
    _setStatus(SocketStatus.connecting);
    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _setStatus(SocketStatus.connected);
      _channel!.stream.listen(
        _handleMessage,
        onError: (Object e, StackTrace _) {
          _lastError = e.toString();
          _setStatus(SocketStatus.failed);
        },
        onDone: () {
          if (_status == SocketStatus.connected) {
            _setStatus(SocketStatus.disconnected);
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SocketStatus.failed);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
    if (_status != SocketStatus.disconnected) {
      _setStatus(SocketStatus.disconnected);
    }
  }

  /// Switches the simulator to a new ECG mode (normal/tachycardia/...).
  void setMode(String mode) {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode({'type': 'set_mode', 'mode': mode}));
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (msg['type']) {
      case 'ecg_sample':
        _samplesController.add(EcgSample.fromJson(msg));
        break;
      case 'beat':
        _beatsController.add(Beat.fromJson(msg));
        break;
      case 'hello':
        _helloController.add(HelloMessage.fromJson(msg));
        break;
    }
  }

  void _setStatus(SocketStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Future<void> dispose() async {
    await disconnect();
    await _samplesController.close();
    await _beatsController.close();
    await _helloController.close();
    await _statusController.close();
  }
}
