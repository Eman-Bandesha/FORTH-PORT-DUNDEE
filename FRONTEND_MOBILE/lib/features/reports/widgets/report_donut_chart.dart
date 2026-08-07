import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/report_models.dart';
import 'report_widgets.dart';

/// A donut chart with a centred total and a colour-coded legend, used by the
/// Category and Location reports.
class ReportDonutChart extends StatelessWidget {
  const ReportDonutChart({
    super.key,
    required this.segments,
    required this.centerLabel,
  });

  final List<NamedQuantity> segments;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final int total = segments.fold<int>(
      0,
      (int sum, NamedQuantity s) => sum + s.quantity,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size(150, 150),
                painter: _DonutPainter(segments: segments, total: total),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < segments.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: kReportPalette[i % kReportPalette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          segments[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${segments[i].quantity}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.total});

  final List<NamedQuantity> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 26;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) {
      final Paint empty = Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(center, radius, empty);
      return;
    }

    double start = -math.pi / 2;
    const double gap = 0.04;
    for (int i = 0; i < segments.length; i++) {
      final double sweep = (segments[i].quantity / total) * 2 * math.pi;
      final Paint paint = Paint()
        ..color = kReportPalette[i % kReportPalette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      final double drawSweep = (sweep - gap).clamp(0.0, 2 * math.pi);
      canvas.drawArc(rect, start + gap / 2, drawSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.total != total;
}
