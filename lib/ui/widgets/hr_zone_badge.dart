import 'package:flutter/material.dart';

import '../../data/models/hr_zone.dart';

class HrZoneBadge extends StatelessWidget {
  final HrZone zone;
  final bool large;

  const HrZoneBadge({super.key, required this.zone, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = zone.color;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 12, vertical: large ? 10 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            zone.label,
            style: TextStyle(
              color: color,
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneStripe extends StatelessWidget {
  final HrZone zone;
  final bool active;

  const _ZoneStripe({required this.zone, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = zone.color;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.6 : 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Row of zone stripes showing the user's current position relative to all
/// five Karvonen zones at once.
class HrZoneTrack extends StatelessWidget {
  final List<({HrZone zone, int low, int high})> ranges;
  final double currentBpm;

  const HrZoneTrack({super.key, required this.ranges, required this.currentBpm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        children: ranges
            .map((r) => _ZoneStripe(
                  zone: r.zone,
                  active: currentBpm >= r.low && currentBpm < r.high,
                ))
            .toList(),
      ),
    );
  }
}
