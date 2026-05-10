import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../data/services/ecg_signal_service.dart';

class ConnectionStatusChip extends StatelessWidget {
  final SignalConnectionStatus status;

  const ConnectionStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _describe(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _describe(SignalConnectionStatus s) {
    switch (s) {
      case SignalConnectionStatus.unsupported:
        return (AppColors.textMuted, 'Sin soporte', Icons.block_rounded);
      case SignalConnectionStatus.disconnected:
        return (AppColors.textMuted, 'Desconectado', Icons.cloud_off_rounded);
      case SignalConnectionStatus.connecting:
        return (AppColors.accentAmber, 'Conectando...', Icons.sync_rounded);
      case SignalConnectionStatus.connected:
        return (AppColors.accentGreen, 'Conectado', Icons.check_circle_rounded);
      case SignalConnectionStatus.failed:
        return (AppColors.accentRed, 'Fallo conexion', Icons.error_rounded);
    }
  }
}
