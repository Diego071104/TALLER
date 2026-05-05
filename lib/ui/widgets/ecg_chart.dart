import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../data/models/ecg_sample.dart';

/// Sliding-window ECG chart. Plots the most recent samples with the newest
/// at the right edge — incoming data pushes old data off the left, mimicking
/// a clinical paper strip.
///
/// X axis is "samples ago" (0 at the right, -windowSize at the left), keeping
/// the line stable while data scrolls. Y axis is fixed millivolt range so a
/// PVC or tall R wave doesn't cause the chart to autoscale and lose its
/// rhythmic context.
class EcgChart extends StatelessWidget {
  final Iterable<EcgSample> samples;
  final int windowSize;

  const EcgChart({
    super.key,
    required this.samples,
    this.windowSize = 1500,
  });

  @override
  Widget build(BuildContext context) {
    final list = samples.toList(growable: false);
    final spots = <FlSpot>[];
    final start = (list.length > windowSize) ? list.length - windowSize : 0;
    for (var i = start; i < list.length; i++) {
      final x = (i - list.length).toDouble(); // negative, newest at 0
      spots.add(FlSpot(x, list[i].mv));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
        child: LineChart(
          LineChartData(
            minX: -windowSize.toDouble(),
            maxX: 0,
            minY: -1.0,
            maxY: 1.6,
            backgroundColor: Colors.transparent,
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 0.5,
              verticalInterval: 250, // 1 second at 250 Hz
              getDrawingHorizontalLine: _gridLine,
              getDrawingVerticalLine: _gridLine,
            ),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            clipData: const FlClipData.all(),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: AppColors.ecgLine,
                barWidth: 1.6,
                dotData: const FlDotData(show: false),
                isStrokeCapRound: true,
              ),
            ],
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  static FlLine _gridLine(double _) =>
      const FlLine(color: AppColors.ecgGrid, strokeWidth: 0.6);
}
