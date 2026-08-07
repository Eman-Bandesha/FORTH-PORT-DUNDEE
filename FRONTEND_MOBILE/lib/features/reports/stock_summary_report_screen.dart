import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'data/reports_repository.dart';
import 'models/report_models.dart';
import 'widgets/report_bar_chart.dart';
import 'widgets/report_widgets.dart';

/// Stock Summary report (design screen 2): headline figures, a stock-status
/// distribution chart and the top categories by quantity.
class StockSummaryReportScreen extends StatefulWidget {
  const StockSummaryReportScreen({super.key});

  @override
  State<StockSummaryReportScreen> createState() =>
      _StockSummaryReportScreenState();
}

class _StockSummaryReportScreenState extends State<StockSummaryReportScreen> {
  DateTimeRange? _range;
  String _location = AppStrings.allLocations;

  String? get _locationFilter =>
      _location == AppStrings.allLocations ? null : _location;

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
    final StockSummaryData data = ReportsRepository.summary(
      location: _locationFilter,
    );
    final List<NamedQuantity> categories = ReportsRepository.byCategory(
      location: _locationFilter,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportStockSummary),
        actions: const <Widget>[ReportsBell(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ReportFilterField(
                    label: AppStrings.dateRangeLabelReport,
                    value: reportRangeLabel(_range),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickRange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ReportDropdownField<String>(
                    label: AppStrings.locationLabel,
                    value: _location,
                    items: <String>[
                      AppStrings.allLocations,
                      ...ReportsRepository.itemLocations,
                    ],
                    labelOf: (String v) => v,
                    onChanged: (String? v) =>
                        setState(() => _location = v ?? AppStrings.allLocations),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: ReportMetricTile(
                    label: AppStrings.statTotalItems,
                    value: '${data.totalItems}',
                    icon: Icons.inventory_2_rounded,
                    iconColor: AppColors.link,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ReportMetricTile(
                    label: AppStrings.totalQuantityReport,
                    value: '${data.totalQuantity} Pcs',
                    icon: Icons.layers_rounded,
                    iconColor: const Color(0xFF8E5BD0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: ReportMetricTile(
                    label: AppStrings.inStock,
                    value: '${data.inStock}',
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF1E8E54),
                    valueColor: const Color(0xFF1E8E54),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ReportMetricTile(
                    label: AppStrings.outOfStock,
                    value: '${data.outOfStock}',
                    icon: Icons.cancel_rounded,
                    iconColor: AppColors.red,
                    valueColor: AppColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: ReportMetricTile(
                    label: AppStrings.lowStock,
                    value: '${data.lowStock}',
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFE8A33D),
                    valueColor: const Color(0xFFE8A33D),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),
            const ReportSectionTitle(AppStrings.stockStatusDistribution),
            const SizedBox(height: 14),
            ReportCard(
              child: ReportBarChart(
                bars: <ReportBar>[
                  ReportBar(
                    label: AppStrings.inStock,
                    value: data.inStock,
                    color: const Color(0xFF1E8E54),
                  ),
                  ReportBar(
                    label: AppStrings.lowStock,
                    value: data.lowStock,
                    color: const Color(0xFFE8A33D),
                  ),
                  ReportBar(
                    label: AppStrings.outOfStock,
                    value: data.outOfStock,
                    color: AppColors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ReportSectionTitle(AppStrings.topCategoriesByQty),
            const SizedBox(height: 14),
            ReportCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _CategoryTable(categories: categories),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.categories});

  final List<NamedQuantity> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 44,
                child: Text(
                  AppStrings.rankHeader,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  AppStrings.categoryLabel,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                AppStrings.quantityHeader,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        if (categories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              AppStrings.noItemsFound,
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          for (int i = 0; i < categories.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      categories[i].name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${categories[i].quantity}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (i != categories.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
      ],
    );
  }
}
