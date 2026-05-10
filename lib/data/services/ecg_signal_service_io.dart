import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ecg_sample.dart';
import 'ecg_signal_service.dart';

class EcgSignalServiceImpl implements EcgSignalService {
  static const int _sampleRate = 250;
  static const String _preferredDeviceName = 'ESP32-ECG';
  static const double _adcMax = 4095.0;
  static const double _adcMid = _adcMax / 2.0;
  static const double _legacySignalSwingAdc = 350.0;
  static const double _normalizedSignalGain = _adcMid / _legacySignalSwingAdc;

  final _samplesController = StreamController<EcgSample>.broadcast();
  final _statusController =
      StreamController<SignalConnectionStatus>.broadcast();
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSub;
  SignalConnectionStatus _status = Platform.isAndroid
      ? SignalConnectionStatus.disconnected
      : SignalConnectionStatus.unsupported;
  String? _lastError = Platform.isAndroid
      ? null
      : 'La conexion ECG nativa solo esta disponible en Android. En web usa Chrome.';
  String? _deviceLabel;
  String _lineBuffer = '';
  double _baselineAdc = _adcMid;
  double _smoothedSignal = 0;

  @override
  Stream<EcgSample> get samples => _samplesController.stream;

  @override
  Stream<SignalConnectionStatus> get statusStream => _statusController.stream;

  @override
  SignalConnectionStatus get status => _status;

  @override
  String? get lastError => _lastError;

  @override
  String? get deviceLabel => _deviceLabel;

  @override
  int get sampleRate => _sampleRate;

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<void> connect() async {
    if (!isSupported) {
      _statusController.add(SignalConnectionStatus.unsupported);
      throw UnsupportedError(_lastError!);
    }

    await disconnect();
    _setStatus(SignalConnectionStatus.connecting);
    _lastError = null;

    try {
      await _ensureBluetoothPermissions();
      await _ensureBluetoothEnabled();

      final device = await _findBondedEcgDevice();
      if (device == null) {
        throw StateError(
          'No se encontro un dispositivo emparejado llamado $_preferredDeviceName. '
          'Emparejalo primero desde la configuracion Bluetooth de Android.',
        );
      }

      final connection = await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      _deviceLabel = '${device.name ?? 'ESP32 ECG'} (${device.address})';
      _baselineAdc = _adcMid;
      _smoothedSignal = 0;
      _lineBuffer = '';

      _inputSub = connection.input?.listen(
        _consumeBytes,
        onDone: _handleRemoteDisconnect,
        onError: _handleConnectionError,
        cancelOnError: true,
      );

      _setStatus(SignalConnectionStatus.connected);
    } catch (e) {
      await _closeConnection();
      _lastError = _friendlyError(e);
      _setStatus(SignalConnectionStatus.failed);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _closeConnection();
    _lineBuffer = '';
    if (_status != SignalConnectionStatus.unsupported) {
      _setStatus(SignalConnectionStatus.disconnected);
    }
  }

  Future<void> _ensureBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final scanStatus =
        statuses[Permission.bluetoothScan] ?? PermissionStatus.denied;
    final connectStatus =
        statuses[Permission.bluetoothConnect] ?? PermissionStatus.denied;
    if (!scanStatus.isGranted || !connectStatus.isGranted) {
      final permanentlyDenied =
          scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied;
      throw StateError(
        permanentlyDenied
            ? 'Los permisos Bluetooth fueron bloqueados. Habilitalos desde Ajustes de Android.'
            : 'La app necesita permisos de Bluetooth para buscar y conectarse al ESP32.',
      );
    }
  }

  Future<void> _ensureBluetoothEnabled() async {
    final enabled = await _bluetooth.isEnabled ?? false;
    if (enabled) {
      return;
    }

    final accepted = await _bluetooth.requestEnable();
    if (accepted != true) {
      throw StateError('Activa Bluetooth en Android para conectarte al ESP32.');
    }
  }

  Future<BluetoothDevice?> _findBondedEcgDevice() async {
    final devices = await _bluetooth.getBondedDevices();
    if (devices.isEmpty) {
      return null;
    }

    for (final device in devices) {
      if ((device.name ?? '').trim() == _preferredDeviceName) {
        return device;
      }
    }

    for (final device in devices) {
      final name = (device.name ?? '').toUpperCase();
      if (name.contains('ESP32') || name.contains('ECG')) {
        return device;
      }
    }

    return null;
  }

  void _consumeBytes(Uint8List data) {
    _consumeChunk(utf8.decode(data, allowMalformed: true));
  }

  void _consumeChunk(String chunk) {
    _lineBuffer += chunk;
    final lines = _lineBuffer.split(RegExp(r'\r?\n'));
    _lineBuffer = lines.removeLast();

    for (final line in lines) {
      _handleLine(line.trim());
    }
  }

  void _handleLine(String line) {
    if (line.isEmpty) {
      return;
    }

    final parts = line.split(',');
    if (parts.length < 2) {
      return;
    }

    final timestampUs = double.tryParse(parts[0]);
    final adcRaw = int.tryParse(parts[1]);
    if (timestampUs == null || adcRaw == null) {
      return;
    }

    _samplesController.add(
      EcgSample(
        timestamp: timestampUs / 1000000.0,
        mv: _normalizeAdc(adcRaw),
        rawAdc: adcRaw,
      ),
    );
  }

  double _normalizeAdc(int adcRaw) {
    final boundedAdc = adcRaw.clamp(0, _adcMax.toInt()).toDouble();
    _baselineAdc = (_baselineAdc * 0.995) + (boundedAdc * 0.005);
    final centered = (boundedAdc - _baselineAdc) / _adcMid;
    final scaledSignal = centered * _normalizedSignalGain;

    _smoothedSignal = (_smoothedSignal * 0.65) + (scaledSignal * 0.35);
    return _smoothedSignal.clamp(-2.0, 2.0);
  }

  void _handleRemoteDisconnect() {
    unawaited(_closeConnection());
    if (_status == SignalConnectionStatus.connected) {
      _setStatus(SignalConnectionStatus.disconnected);
    }
  }

  void _handleConnectionError(Object error, [StackTrace? _]) {
    _lastError = _friendlyError(error);
    unawaited(_closeConnection());
    _setStatus(SignalConnectionStatus.failed);
  }

  Future<void> _closeConnection() async {
    final inputSub = _inputSub;
    _inputSub = null;
    if (inputSub != null) {
      await inputSub.cancel();
    }

    final connection = _connection;
    _connection = null;
    if (connection != null) {
      try {
        await connection.finish();
      } catch (_) {
        try {
          await connection.close();
        } catch (_) {
          // Ignore teardown errors after link loss.
        }
      }
    }

    _deviceLabel = null;
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('BLUETOOTH_SCAN')) {
      return 'Android rechazo el permiso para buscar dispositivos Bluetooth. Acepta "dispositivos cercanos" e intenta de nuevo.';
    }
    if (text.contains('bluetoothConnect')) {
      return 'Android rechazo el permiso Bluetooth. Concedelo e intenta de nuevo.';
    }
    if (text.contains('bonded')) {
      return 'No se encontro el ESP32 emparejado en Android.';
    }
    return text;
  }

  void _setStatus(SignalConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _samplesController.close();
    await _statusController.close();
  }
}
