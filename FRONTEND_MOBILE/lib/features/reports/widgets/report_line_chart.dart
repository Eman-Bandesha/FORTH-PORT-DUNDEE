import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../models/report_models.dart';

/// A dual-series line chart (Stock In vs Stock Out) for the Stock In/Out report.
///
/// Hand-painted so the app stays dependency-free.
class ReportLineChart extends StatelessWidget {
  const ReportLineChart({super.key, required this.trend});

  final List<TrendDay> trend;

  static const Color _inColor = Color(0xFF1E8E54);
  static const Color _outColor = AppColors.red;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: const <Widget>[
            _LegendDot(color: _inColor, label: AppStrings.stockIn),
            SizedBox(width: 18),
            _LegendDot(color: _outColor, label: AppStrings.stockOut),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: Size.infinite,
            painter: _LinePainter(
              trend: trend,
              inColor: _inColor,
              outColor: _outColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.trend,
    required this.inColor,
    required this.outColor,
  });

  final List<TrendDay> trend;
  final Color inColor;
  final Color outColor;

  static const double _leftPad = 34;
  static const double _rightPad = 8;
  static const double _topPad = 10;
  static const double _bottomPad = 24;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) return;

    final double chartLeft = _leftPad;
    final double chartRight = size.width - _rightPad;
    final double chartTop = _topPad;
    final double chartBottom = size.height - _bottomPad;
    final double chartWidth = chartRight - chartLeft;
    final double chartHeight = chartBottom - chartTop;

    int maxValue = 0;
    for (final TrendDay p in trend) {
      maxValue = <int>[
        maxValue,
        p.stockIn,
        p.stockOut,
      ].reduce((int a, int b) => a > b ? a : b);
    }
    final int step = maxValue > 400 ? 200 : 100;
    final int yMax = ((maxValue / step).ceil() * step).clamp(step, 100000);

    final Paint gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (int value = 0; value <= yMax; value += step) {
      final double y = chartBottom - (value / yMax) * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _drawText(
        canvas,
        '$value',
        Offset(chartLeft - 6, y),
        anchorRight: true,
        anchorMiddleV: true,
      );
    }

    double xFor(int index) =>
        chartLeft +
        (trend.length == 1 ? 0 : chartWidth * index / (trend.length - 1));
    double yFor(int value) => chartBottom - (value / yMax) * chartHeight;

    for (int i = 0; i < trend.length; i++) {
      _drawText(
        canvas,
        trend[i].label,
        Offset(xFor(i), chartBottom + 8),
        anchorCenterH: true,
        fontSize: 9.5,
      );
    }

    void drawSeries(int Function(TrendDay) selector, Color color) {
      final Paint linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final Paint dotPaint = Paint()..color = color;

      final Path path = Path();
      for (int i = 0; i < trend.length; i++) {
        final Offset point = Offset(xFor(i), yFor(selector(trend[i])));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, linePaint);
      for (int i = 0; i < trend.length; i++) {
        canvas.drawCircle(Offset(xFor(i), yFor(selector(trend[i]))), 3, dotPaint);
      }
    }

    drawSeries((TrendDay p) => p.stockIn, inColor);
    drawSeries((TrendDay p) => p.stockOut, outColor);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    bool anchorRight = false,
    bool anchorCenterH = false,
    bool anchorMiddleV = false,
    double fontSize = 10,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: AppColors.textMuted, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double dx = offset.dx;
    double dy = offset.dy;
    if (anchorRight) dx -= tp.width;
    if (anchorCenterH) dx -= tp.width / 2;
    if (anchorMiddleV) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.trend != trend;
}
