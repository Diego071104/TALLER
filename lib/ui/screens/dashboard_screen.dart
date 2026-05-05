import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../data/models/hr_zone.dart';
import '../../data/models/user_profile.dart';
import '../../logic/health_analyzer.dart';
import '../../state/connection_provider.dart';
import '../../state/ecg_stream_provider.dart';
import '../../state/user_profile_provider.dart';
import '../widgets/bpm_indicator.dart';
import '../widgets/connection_status_chip.dart';
import '../widgets/ecg_chart.dart';
import '../widgets/hr_zone_badge.dart';
import 'recommendation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _fallbackProfile = UserProfile(
    ageYears: 25,
    weightKg: 70,
    heightCm: 170,
    sex: Sex.other,
    activity: ActivityLevel.moderate,
  );

  @override
  Widget build(BuildContext context) {
    final stream = context.watch<EcgStreamProvider>();
    final connection = context.watch<ConnectionProvider>();
    final profile =
        context.watch<UserProfileProvider>().profile ?? _fallbackProfile;
    const analyzer = HealthAnalyzer();
    final ranges = analyzer.zonesFor(profile);
    final smoothed = stream.smoothedBpm ?? 0;
    final zone = analyzer.classify(smoothed, ranges);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Monitor en vivo'),
            const SizedBox(width: 12),
            ConnectionStatusChip(status: connection.status),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recomendación',
            icon: const Icon(Icons.health_and_safety_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecommendationScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopRow(
                  bpm: stream.smoothedBpm,
                  zone: zone,
                  rmssdMs: stream.rmssdMs),
              const SizedBox(height: 12),
              _ZoneTrackCard(currentBpm: smoothed, ranges: ranges, zone: zone),
              const SizedBox(height: 16),
              Expanded(
                child: EcgChart(samples: stream.samples),
              ),
              const SizedBox(height: 12),
              _StatsRow(
                lastRr: stream.lastBeat?.rrMs,
                bpmInstant: stream.lastBeat?.instantBpm,
                samplesInBuffer: stream.sampleCount,
                sampleRate: connection.sampleRate,
              ),
              const SizedBox(height: 12),
              _ModeSelector(
                modes: connection.availableModes,
                current: connection.mode,
                onSelect: (m) => connection.changeMode(m),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final double? bpm;
  final HrZone zone;
  final double? rmssdMs;

  const _TopRow({required this.bpm, required this.zone, required this.rmssdMs});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: BpmIndicator(bpm: bpm, accent: zone.color)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            HrZoneBadge(zone: zone, large: true),
            const SizedBox(height: 8),
            Text(
              'HRV ${rmssdMs == null ? '--' : rmssdMs!.toStringAsFixed(0)} ms',
              style: AppTheme.monoNumeric(
                  size: 13,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ZoneTrackCard extends StatelessWidget {
  final double currentBpm;
  final List<ZoneRange> ranges;
  final HrZone zone;

  const _ZoneTrackCard(
      {required this.currentBpm, required this.ranges, required this.zone});

  @override
  Widget build(BuildContext context) {
    final mapped = ranges
        .map((r) => (zone: r.zone, low: r.lowerBpm, high: r.upperBpm))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded,
                    color: AppColors.accentCyan, size: 16),
                const SizedBox(width: 8),
                const Text('Zonas de Karvonen',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  '${ranges.first.upperBpm}–${ranges.last.lowerBpm} BPM',
                  style: AppTheme.monoNumeric(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            HrZoneTrack(ranges: mapped, currentBpm: currentBpm),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double? lastRr;
  final double? bpmInstant;
  final int samplesInBuffer;
  final int? sampleRate;

  const _StatsRow({
    required this.lastRr,
    required this.bpmInstant,
    required this.samplesInBuffer,
    required this.sampleRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatTile(
                label: 'RR',
                value: lastRr == null ? '--' : lastRr!.toStringAsFixed(0),
                unit: 'ms')),
        Expanded(
            child: _StatTile(
                label: 'BPM inst',
                value: bpmInstant == null
                    ? '--'
                    : bpmInstant!.toStringAsFixed(0),
                unit: '')),
        Expanded(
            child: _StatTile(
                label: 'Buffer',
                value: '$samplesInBuffer',
                unit: 'pts')),
        Expanded(
            child: _StatTile(
                label: 'Tasa',
                value: sampleRate == null ? '--' : '$sampleRate',
                unit: 'Hz')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatTile({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: AppTheme.monoNumeric(
                        size: 18, weight: FontWeight.w600)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1.5),
                    child: Text(unit,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final List<String> modes;
  final String? current;
  final void Function(String) onSelect;

  const _ModeSelector(
      {required this.modes, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (modes.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modes.map((m) {
          final selected = m == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(m)),
              selected: selected,
              onSelected: (_) => onSelect(m),
              selectedColor: AppColors.accentCyan.withValues(alpha: 0.18),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected ? AppColors.accentCyan : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected ? AppColors.accentCyan : AppColors.divider,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(String mode) {
    switch (mode) {
      case 'normal':
        return 'Normal';
      case 'tachycardia':
        return 'Taquicardia';
      case 'bradycardia':
        return 'Bradicardia';
      case 'arrhythmia':
        return 'Arritmia';
      case 'exercise':
        return 'Ejercicio';
      default:
        return mode;
    }
  }
}
