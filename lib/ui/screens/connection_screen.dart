import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../data/services/ecg_signal_service.dart';
import '../../state/connection_provider.dart';
import '../../state/user_profile_provider.dart';
import '../widgets/connection_status_chip.dart';
import 'profile_form_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  Future<void> _onConnect() async {
    final connection = context.read<ConnectionProvider>();
    await connection.connect();
    if (!mounted) {
      return;
    }
    if (connection.status == SignalConnectionStatus.connected) {
      _proceed();
    }
  }

  void _proceed() {
    final hasProfile = context.read<UserProfileProvider>().hasProfile;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(skipIfFilled: hasProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isWebSerial = kIsWeb;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Header(isAndroid: isAndroid, isWebSerial: isWebSerial),
            const SizedBox(height: 32),
            _DeviceCard(
              status: connection.status,
              deviceLabel: connection.deviceLabel,
              isAndroid: isAndroid,
            ),
            const SizedBox(height: 24),
            _BluetoothInstructions(
              isAndroid: isAndroid,
              isWebSerial: isWebSerial,
            ),
            if (!connection.isSupported) ...[
              const SizedBox(height: 24),
              _ErrorBanner(
                message: isWebSerial
                    ? 'Este navegador no expone Web Serial. Usa Chrome o Edge sobre http://localhost o HTTPS.'
                    : 'Esta plataforma no soporta la conexion ECG aqui. Usa la APK en Android o la app web en Chrome.',
              ),
            ],
            if (connection.lastError != null &&
                connection.status == SignalConnectionStatus.failed) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: connection.lastError!),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !connection.isSupported ||
                        connection.status == SignalConnectionStatus.connecting
                    ? null
                    : _onConnect,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: Text(
                  connection.status == SignalConnectionStatus.connected
                      ? 'Volver a conectar'
                      : 'Conectar ESP32',
                ),
              ),
            ),
            if (connection.status == SignalConnectionStatus.connected) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _proceed,
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isAndroid;
  final bool isWebSerial;

  const _Header({
    required this.isAndroid,
    required this.isWebSerial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.accentTeal],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.background,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'VitalSync',
              style: AppTheme.monoNumeric(size: 22, weight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isAndroid
              ? 'Empareja el ESP32 desde Android y conecta desde la app para iniciar la adquisicion ECG.'
              : isWebSerial
                  ? 'Abre la app web en Chrome o Edge y selecciona el puerto serial Bluetooth del ESP32 para iniciar la adquisicion ECG.'
                  : 'Usa la APK en Android o la app web en Chrome para iniciar la adquisicion ECG.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final SignalConnectionStatus status;
  final String? deviceLabel;
  final bool isAndroid;

  const _DeviceCard({
    required this.status,
    required this.deviceLabel,
    required this.isAndroid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.sensors_rounded,
                color: AppColors.accentCyan,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESP32 ECG por Bluetooth',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceLabel ??
                        (isAndroid
                            ? 'Esperando conexion con un dispositivo emparejado'
                            : 'Esperando seleccion del puerto serial Bluetooth'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ConnectionStatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

class _BluetoothInstructions extends StatelessWidget {
  final bool isAndroid;
  final bool isWebSerial;

  const _BluetoothInstructions({
    required this.isAndroid,
    required this.isWebSerial,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isAndroid
              ? const [
                  _StepRow(
                    index: '1',
                    text:
                        'Empareja el dispositivo ESP32-ECG desde la configuracion Bluetooth de Android.',
                  ),
                  SizedBox(height: 12),
                  _StepRow(
                    index: '2',
                    text:
                        'Pulsa Conectar ESP32 y concede el permiso Bluetooth cuando Android lo solicite.',
                  ),
                  SizedBox(height: 12),
                  _StepRow(
                    index: '3',
                    text:
                        'La app se conectara al ESP32 emparejado y arrancara la grafica ECG sin necesitar Chrome.',
                  ),
                ]
              : isWebSerial
                  ? const [
                      _StepRow(
                        index: '1',
                        text:
                            'Empareja el dispositivo ESP32-ECG con el sistema operativo antes de abrir el selector.',
                      ),
                      SizedBox(height: 12),
                      _StepRow(
                        index: '2',
                        text:
                            'Pulsa Conectar ESP32 para que Chrome o Edge abra el selector de puertos seriales.',
                      ),
                      SizedBox(height: 12),
                      _StepRow(
                        index: '3',
                        text:
                            'Selecciona el puerto Bluetooth del ESP32. La grafica y el calculo de BPM iniciaran al conectarse.',
                      ),
                    ]
                  : const [
                      _StepRow(
                        index: '1',
                        text:
                            'Instala la APK en Android para Bluetooth nativo o usa la version web en Chrome.',
                      ),
                    ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String index;
  final String text;

  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
          ),
          child: Text(
            index,
            style: AppTheme.monoNumeric(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.accentCyan,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
