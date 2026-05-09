import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../models/ecg_sample.dart';
import 'ecg_signal_service.dart';

class EcgSignalServiceImpl implements EcgSignalService {
  static const int _sampleRate = 250;
  static const int _bluetoothSppServiceClassId = 0x1101;
  static const double _adcMax = 4095.0;
  static const double _adcMid = _adcMax / 2.0;
  static const double _legacySignalSwingAdc = 350.0;
  static const double _normalizedSignalGain = _adcMid / _legacySignalSwingAdc;

  final _samplesController = StreamController<EcgSample>.broadcast();
  final _statusController =
      StreamController<SignalConnectionStatus>.broadcast();

  JSObject? _port;
  JSObject? _reader;
  JSObject? _textDecoder;
  SignalConnectionStatus _status = SignalConnectionStatus.disconnected;
  String? _lastError;
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
  bool get isSupported => web.window.navigator.has('serial');

  @override
  Future<void> connect() async {
    await disconnect();
    if (!isSupported) {
      _lastError =
          'Chrome no expone Web Serial aqui. Usa Chrome de escritorio en http://localhost o HTTPS.';
      _setStatus(SignalConnectionStatus.unsupported);
      throw UnsupportedError(_lastError!);
    }

    _setStatus(SignalConnectionStatus.connecting);
    _lastError = null;

    try {
      final serial = web.window.navigator['serial'] as JSObject?;
      if (serial == null) {
        throw UnsupportedError('Navigator.serial no esta disponible.');
      }

      final requestOptions = {
        'filters': [
          {'bluetoothServiceClassId': _bluetoothSppServiceClassId},
        ],
      }.jsify()! as JSObject;

      _port = await serial
          .callMethod<JSPromise<JSObject>>('requestPort'.toJS, requestOptions)
          .toDart;

      final openOptions = {'baudRate': 115200}.jsify()! as JSObject;
      await _port!
          .callMethod<JSPromise<JSAny?>>('open'.toJS, openOptions)
          .toDart;

      _deviceLabel = _describePort();
      final textDecoderCtor = web.window['TextDecoder'] as JSFunction?;
      _textDecoder = textDecoderCtor?.callAsConstructor<JSObject>();
      if (_textDecoder == null) {
        throw StateError('No fue posible crear TextDecoder.');
      }

      final readable = _port!['readable'] as JSObject?;
      _reader = readable?.callMethod<JSObject>('getReader'.toJS);
      if (_reader == null) {
        throw StateError('El puerto serial no expuso un lector legible.');
      }

      _baselineAdc = _adcMid;
      _smoothedSignal = 0;
      _lineBuffer = '';

      _setStatus(SignalConnectionStatus.connected);
      unawaited(_readLoop());
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SignalConnectionStatus.failed);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final reader = _reader;
    _reader = null;

    if (reader != null) {
      try {
        await reader.callMethod<JSPromise<JSAny?>>('cancel'.toJS).toDart;
      } catch (_) {
        // Ignore expected cancellation errors on disconnect.
      }
      try {
        reader.callMethod<JSAny?>('releaseLock'.toJS);
      } catch (_) {
        // Ignore.
      }
    }

    final port = _port;
    _port = null;
    if (port != null) {
      try {
        await port.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
      } catch (_) {
        // Ignore close errors after a dropped wireless link.
      }
    }

    _lineBuffer = '';
    _textDecoder = null;
    if (_status != SignalConnectionStatus.disconnected &&
        _status != SignalConnectionStatus.unsupported) {
      _setStatus(SignalConnectionStatus.disconnected);
    }
  }

  Future<void> _readLoop() async {
    final reader = _reader;
    if (reader == null) {
      return;
    }

    try {
      while (_reader == reader) {
        final result = await reader
            .callMethod<JSPromise<JSObject>>('read'.toJS)
            .toDart;
        final done = (result['done'] as JSBoolean?)?.toDart ?? false;
        if (done) {
          break;
        }

        final value = result['value'];
        if (value == null) {
          continue;
        }

        final chunk = (_textDecoder!
                .callMethod<JSString>(
                  'decode'.toJS,
                  value,
                  {'stream': true}.jsify(),
                ))
            .toDart;

        _consumeChunk(chunk);
      }

      if (_status == SignalConnectionStatus.connected) {
        _setStatus(SignalConnectionStatus.disconnected);
      }
    } catch (e) {
      if (_reader != reader) {
        return;
      }
      _lastError = e.toString();
      _setStatus(SignalConnectionStatus.failed);
    }
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

    // Normalize against the full 12-bit ESP32 ADC range and then scale back
    // to the detector's expected amplitude so BPM extraction remains stable.
    final centered = (boundedAdc - _baselineAdc) / _adcMid;
    final scaledSignal = centered * _normalizedSignalGain;

    _smoothedSignal = (_smoothedSignal * 0.65) + (scaledSignal * 0.35);
    return _smoothedSignal.clamp(-2.0, 2.0);
  }

  String _describePort() {
    try {
      final info = _port?.callMethod<JSObject>('getInfo'.toJS);
      final hasBluetoothId =
          (info?.has('bluetoothServiceClassId') ?? false);
      if (hasBluetoothId) {
        return 'ESP32 ECG por Bluetooth';
      }
    } catch (_) {
      // Ignore.
    }
    return 'Puerto serial Bluetooth';
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
