import '../models/ecg_sample.dart';
import 'ecg_signal_service_stub.dart'
    if (dart.library.io) 'ecg_signal_service_io.dart'
    if (dart.library.html) 'ecg_signal_service_web.dart' as impl;

enum SignalConnectionStatus {
  unsupported,
  disconnected,
  connecting,
  connected,
  failed,
}

abstract class EcgSignalService {
  factory EcgSignalService() = impl.EcgSignalServiceImpl;

  Stream<EcgSample> get samples;
  Stream<SignalConnectionStatus> get statusStream;

  SignalConnectionStatus get status;
  String? get lastError;
  String? get deviceLabel;
  int get sampleRate;
  bool get isSupported;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> dispose();
}
