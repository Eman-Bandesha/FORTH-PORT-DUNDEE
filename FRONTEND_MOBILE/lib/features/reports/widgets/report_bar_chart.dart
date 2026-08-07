import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A single bar in [ReportBarChart].
class ReportBar {
  const ReportBar({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;
}

/// A simple vertical bar chart (no external dependencies).
///
/// Bars are scaled to the largest value; the count is printed above each bar
/// and the category label below it.
class ReportBarChart extends StatelessWidget {
  const ReportBarChart({
    super.key,
    required this.bars,
    this.barAreaHeight = 140,
    this.barWidth = 42,
  });

  final List<ReportBar> bars;
  final double barAreaHeight;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final int maxValue = bars.fold<int>(
      0,
      (int m, ReportBar b) => b.value > m ? b.value : m,
    );
    final double safeMax = (maxValue == 0 ? 1 : maxValue) * 1.15;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final ReportBar bar in bars)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${bar.value}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: barWidth,
                  height: (bar.value / safeMax) * barAreaHeight + 2,
                  decoration: BoxDecoration(
                    color: bar.color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bar.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
