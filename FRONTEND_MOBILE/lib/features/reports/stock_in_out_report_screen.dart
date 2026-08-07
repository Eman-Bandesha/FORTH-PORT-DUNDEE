import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../movements/models/movement.dart';
import 'data/reports_repository.dart';
import 'models/report_models.dart';
import 'widgets/report_line_chart.dart';
import 'widgets/report_widgets.dart';

/// Stock In / Out report (design screen 4): movement trend, totals and the
/// most recent movements for the selected direction.
class StockInOutReportScreen extends StatefulWidget {
  const StockInOutReportScreen({super.key});

  @override
  State<StockInOutReportScreen> createState() =>
      _StockInOutReportScreenState();
}

class _StockInOutReportScreenState extends State<StockInOutReportScreen> {
  static const Color _inColor = Color(0xFF1E8E54);
  static const Color _outColor = AppColors.red;

  MovementType _type = MovementType.stockIn;
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final List<TrendDay> trend = ReportsRepository.movementTrend;
    final int totalIn = trend.fold<int>(0, (int s, TrendDay d) => s + d.stockIn);
    final int totalOut =
        trend.fold<int>(0, (int s, TrendDay d) => s + d.stockOut);
    final int net = totalIn - totalOut;
    final List<Movement> recent = ReportsRepository.recentMovements(_type);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportStockInOut),
        actions: const <Widget>[ReportsBell(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: <Widget>[
            _Segmented(
              type: _type,
              onChanged: (MovementType t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
            ReportFilterField(
              label: AppStrings.dateRangeLabelReport,
              value: reportRangeLabel(_range),
              icon: Icons.calendar_today_rounded,
              onTap: _pickRange,
            ),
            const SizedBox(height: 22),
            const ReportSectionTitle(AppStrings.stockMovementTrend),
            const SizedBox(height: 14),
            ReportCard(child: ReportLineChart(trend: trend)),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TotalCard(
                    label: AppStrings.totalStockIn,
                    value: '$totalIn',
                    color: _inColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TotalCard(
                    label: AppStrings.totalStockOut,
                    value: '$totalOut',
                    color: _outColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TotalCard(
                    label: AppStrings.netMovementReport,
                    value: '${net >= 0 ? '+' : ''}$net',
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ReportSectionTitle(AppStrings.recentMovements),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  AppStrings.noMovementsFound,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ReportCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < recent.length; i++) ...<Widget>[
                      _MovementRow(movement: recent[i]),
                      if (i != recent.length - 1)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.type, required this.onChanged});

  final MovementType type;
  final ValueChanged<MovementType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          _SegmentButton(
            label: AppStrings.stockIn,
            selected: type == MovementType.stockIn,
            onTap: () => onChanged(MovementType.stockIn),
          ),
          _SegmentButton(
            label: AppStrings.stockOut,
            selected: type == MovementType.stockOut,
            onTap: () => onChanged(MovementType.stockOut),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.textMuted,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final Color color = movement.isIn
        ? const Color(0xFF1E8E54)
        : AppColors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              movement.isIn
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  movement.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movement.dateTimeLabel} · ${movement.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${movement.changeLabel} ${movement.unit}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
