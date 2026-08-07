import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../models/stock_analytics.dart';

/// A compact multi-series line chart (In / Out / Stock) for the last 7 days.
///
/// Hand-painted so the app stays dependency-free.
class StockTrendChart extends StatelessWidget {
  const StockTrendChart({super.key, required this.trend});

  final List<StockTrendPoint> trend;

  static const Color _inColor = Color(0xFF1E8E54);
  static const Color _outColor = AppColors.red;
  static const Color _stockColor = AppColors.link;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: const <Widget>[
            _LegendDot(color: _inColor, label: AppStrings.trendLegendIn),
            _LegendDot(color: _outColor, label: AppStrings.trendLegendOut),
            _LegendDot(color: _stockColor, label: AppStrings.trendLegendStock),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: Size.infinite,
            painter: _TrendPainter(
              trend: trend,
              inColor: _inColor,
              outColor: _outColor,
              stockColor: _stockColor,
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

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.trend,
    required this.inColor,
    required this.outColor,
    required this.stockColor,
  });

  final List<StockTrendPoint> trend;
  final Color inColor;
  final Color outColor;
  final Color stockColor;

  static const double _leftPad = 30;
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

    // Determine a sensible y-axis maximum, rounded up to the nearest 20.
    int maxValue = 0;
    for (final StockTrendPoint p in trend) {
      maxValue = <int>[
        maxValue,
        p.stockIn,
        p.stockOut,
        p.stockLevel,
      ].reduce((int a, int b) => a > b ? a : b);
    }
    final int yMax = ((maxValue / 20).ceil() * 20).clamp(20, 100000);

    final Paint gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // Horizontal gridlines + y-axis labels (0, 20, 40, ...).
    for (int value = 0; value <= yMax; value += 20) {
      final double y = chartBottom - (value / yMax) * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      _drawText(
        canvas,
        '$value',
        Offset(chartLeft - 6, y),
        align: TextAlign.right,
        anchorRight: true,
        anchorMiddleV: true,
      );
    }

    double xFor(int index) =>
        chartLeft +
        (trend.length == 1 ? 0 : chartWidth * index / (trend.length - 1));
    double yFor(int value) => chartBottom - (value / yMax) * chartHeight;

    // X-axis labels.
    for (int i = 0; i < trend.length; i++) {
      _drawText(
        canvas,
        trend[i].label,
        Offset(xFor(i), chartBottom + 8),
        align: TextAlign.center,
        anchorCenterH: true,
        fontSize: 9.5,
      );
    }

    void drawSeries(int Function(StockTrendPoint) selector, Color color) {
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
        canvas.drawCircle(
          Offset(xFor(i), yFor(selector(trend[i]))),
          3,
          dotPaint,
        );
      }
    }

    drawSeries((StockTrendPoint p) => p.stockIn, inColor);
    drawSeries((StockTrendPoint p) => p.stockOut, outColor);
    drawSeries((StockTrendPoint p) => p.stockLevel, stockColor);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    TextAlign align = TextAlign.left,
    bool anchorRight = false,
    bool anchorCenterH = false,
    bool anchorMiddleV = false,
    double fontSize = 10,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
        ).copyWith(fontSize: fontSize),
      ),
      textAlign: align,
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
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.trend != trend;
}
