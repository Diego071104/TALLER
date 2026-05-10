import 'dart:async';

import '../models/ecg_sample.dart';
import 'ecg_signal_service.dart';

class EcgSignalServiceImpl implements EcgSignalService {
  final _samplesController = StreamController<EcgSample>.broadcast();
  final _statusController =
      StreamController<SignalConnectionStatus>.broadcast();

  final String _lastError =
      'La adquisicion Web Serial solo esta disponible en Chrome sobre la app web.';

  @override
  Stream<EcgSample> get samples => _samplesController.stream;

  @override
  Stream<SignalConnectionStatus> get statusStream => _statusController.stream;

  @override
  SignalConnectionStatus get status => SignalConnectionStatus.unsupported;

  @override
  String? get lastError => _lastError;

  @override
  String? get deviceLabel => null;

  @override
  int get sampleRate => 250;

  @override
  bool get isSupported => false;

  @override
  Future<void> connect() async {
    _statusController.add(SignalConnectionStatus.unsupported);
    throw UnsupportedError(_lastError);
  }

  @override
  Future<void> disconnect() async {
    _statusController.add(SignalConnectionStatus.unsupported);
  }

  @override
  Future<void> dispose() async {
    await _samplesController.close();
    await _statusController.close();
  }
}
