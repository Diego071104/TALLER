import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';

/// Big BPM readout with a heart that pulses in sync with the actual rate.
/// The pulse animation period is recomputed when bpm changes so a sensed
/// 120 BPM beats twice as often as 60 BPM, giving demos a tactile feel.
class BpmIndicator extends StatefulWidget {
  final double? bpm;
  final Color accent;

  const BpmIndicator({super.key, required this.bpm, this.accent = AppColors.accentCyan});

  @override
  State<BpmIndicator> createState() => _BpmIndicatorState();
}

class _BpmIndicatorState extends State<BpmIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _periodFor(widget.bpm),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BpmIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      _ctrl.duration = _periodFor(widget.bpm);
      _ctrl
        ..reset()
        ..repeat(reverse: true);
    }
  }

  Duration _periodFor(double? bpm) {
    if (bpm == null || bpm <= 0) return const Duration(milliseconds: 500);
    // Half-cycle = beat period -> animation reverses to look like a pulse.
    final ms = (60_000 / bpm / 2).clamp(120, 1200).toInt();
    return Duration(milliseconds: ms);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bpmText = widget.bpm == null ? '--' : widget.bpm!.round().toString();
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded, color: widget.accent, size: 28),
              const SizedBox(width: 8),
              Text('Frecuencia cardíaca',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(bpmText,
                  style: AppTheme.monoNumeric(
                      size: 64, weight: FontWeight.w700, color: widget.accent)),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('BPM',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
