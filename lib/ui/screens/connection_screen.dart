import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../data/services/ecg_socket_service.dart';
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
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<ConnectionProvider>().serverUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _onConnect() async {
    final connection = context.read<ConnectionProvider>();
    connection.setServerUrl(_urlController.text.trim());
    await connection.connect();
    if (!mounted) return;
    if (connection.status == SocketStatus.connected) {
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 32),
              _DeviceCard(status: connection.status, mode: connection.mode),
              const SizedBox(height: 24),
              _ServerSettings(controller: _urlController, status: connection.status),
              const Spacer(),
              if (connection.lastError != null && connection.status == SocketStatus.failed)
                _ErrorBanner(message: connection.lastError!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: connection.status == SocketStatus.connecting
                      ? null
                      : _onConnect,
                  icon: const Icon(Icons.bluetooth_searching_rounded),
                  label: Text(
                    connection.status == SocketStatus.connected
                        ? 'Continuar'
                        : 'Conectar al sensor',
                  ),
                ),
              ),
              if (connection.status == SocketStatus.connected) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _proceed,
                    child: const Text('Saltar a mi perfil'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
              child: const Icon(Icons.monitor_heart_rounded,
                  color: AppColors.background, size: 24),
            ),
            const SizedBox(width: 12),
            Text('VitalSync',
                style: AppTheme.monoNumeric(size: 22, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Conecta tu sensor para empezar el monitoreo de ECG',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final SocketStatus status;
  final String? mode;

  const _DeviceCard({required this.status, required this.mode});

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
              child: const Icon(Icons.sensors_rounded,
                  color: AppColors.accentCyan, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sensor ECG (simulador)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    mode != null ? 'Modo activo: $mode' : 'WebSocket localhost',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
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

class _ServerSettings extends StatelessWidget {
  final TextEditingController controller;
  final SocketStatus status;

  const _ServerSettings({required this.controller, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dirección del simulador',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: status != SocketStatus.connecting &&
              status != SocketStatus.connected,
          decoration: const InputDecoration(
            hintText: 'ws://localhost:8765',
            prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted),
          ),
          style: AppTheme.monoNumeric(size: 14, weight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        const Text(
          'Si corres en celular físico, usa la IP de tu laptop en la misma red WiFi (ej. ws://192.168.1.42:8765).',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
          const Icon(Icons.error_outline_rounded,
              color: AppColors.accentRed, size: 18),
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
