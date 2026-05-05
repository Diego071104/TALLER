import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../data/models/hr_zone.dart';
import '../../data/models/user_profile.dart';
import '../../logic/health_analyzer.dart';
import '../../state/ecg_stream_provider.dart';
import '../../state/user_profile_provider.dart';
import '../widgets/hr_zone_badge.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>().profile;
    final stream = context.watch<EcgStreamProvider>();

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recomendación')),
        body: const _NoProfilePrompt(),
      );
    }

    final smoothed = stream.smoothedBpm ?? 0;
    final analysis = const HealthAnalyzer().analyze(
      profile: profile,
      smoothedBpm: smoothed,
      rmssdMs: stream.rmssdMs,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recomendación')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header(
              bpm: smoothed,
              zone: analysis.currentZone,
              bmi: analysis.bmi,
            ),
            const SizedBox(height: 24),
            _SectionTitle(
                icon: Icons.health_and_safety_rounded,
                text: 'Análisis personalizado'),
            const SizedBox(height: 12),
            ...analysis.alerts.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AlertCard(alert: a),
                )),
            const SizedBox(height: 24),
            _SectionTitle(
                icon: Icons.insights_rounded, text: 'Tus zonas cardíacas'),
            const SizedBox(height: 12),
            _ZoneBreakdown(
                analysis: analysis, currentBpm: smoothed, profile: profile),
            const SizedBox(height: 24),
            _Footnotes(profile: profile),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double bpm;
  final HrZone zone;
  final double bmi;

  const _Header({required this.bpm, required this.zone, required this.bmi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BPM promedio reciente',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(bpm == 0 ? '--' : bpm.toStringAsFixed(0),
                    style: AppTheme.monoNumeric(
                        size: 48,
                        weight: FontWeight.w700,
                        color: AppColors.accentCyan)),
                const SizedBox(height: 8),
                HrZoneBadge(zone: zone, large: true),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('IMC',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text(bmi.toStringAsFixed(1),
                  style: AppTheme.monoNumeric(size: 32, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_bmiLabel(bmi),
                  style: TextStyle(
                      color: _bmiColor(bmi),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  static String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Saludable';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  static Color _bmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.accentAmber;
    if (bmi < 25) return AppColors.accentGreen;
    if (bmi < 30) return AppColors.accentAmber;
    return AppColors.accentRed;
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentCyan, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final HealthAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(alert.severity);
    final icon = _iconFor(alert.severity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(alert.message,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorFor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.success:
        return AppColors.accentGreen;
      case AlertSeverity.warning:
        return AppColors.accentAmber;
      case AlertSeverity.danger:
        return AppColors.accentRed;
      case AlertSeverity.info:
        return AppColors.accentCyan;
    }
  }

  static IconData _iconFor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.success:
        return Icons.check_circle_rounded;
      case AlertSeverity.warning:
        return Icons.warning_rounded;
      case AlertSeverity.danger:
        return Icons.error_rounded;
      case AlertSeverity.info:
        return Icons.info_rounded;
    }
  }
}

class _ZoneBreakdown extends StatelessWidget {
  final HealthAnalysis analysis;
  final double currentBpm;
  final UserProfile profile;

  const _ZoneBreakdown({
    required this.analysis,
    required this.currentBpm,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: analysis.zoneRanges.map((r) {
        final isActive = r.contains(currentBpm);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? r.zone.color.withValues(alpha: 0.10)
                : AppColors.surface,
            border: Border.all(
              color: isActive ? r.zone.color : AppColors.divider,
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: r.zone.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(r.zone.label,
                    style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
              ),
              Text(
                '${r.lowerBpm}–${r.upperBpm == 9999 ? "∞" : r.upperBpm} BPM',
                style: AppTheme.monoNumeric(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Footnotes extends StatelessWidget {
  final UserProfile profile;
  const _Footnotes({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Cálculo basado en perfil: ${profile.ageYears} años, '
                '${profile.activity.label.toLowerCase()}.'),
            Text(
                'HR máx teórica (Tanaka 208 - 0.7×edad): ${profile.maxHr} BPM. '
                'HR reposo estimada: ${profile.restingHr} BPM.'),
            const SizedBox(height: 6),
            const Text(
                'Las recomendaciones son orientativas y no sustituyen evaluación médica profesional.'),
          ],
        ),
      ),
    );
  }
}

class _NoProfilePrompt extends StatelessWidget {
  const _NoProfilePrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text('Sin perfil capturado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Necesitamos tus datos demográficos para calcular zonas y emitir recomendaciones.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
