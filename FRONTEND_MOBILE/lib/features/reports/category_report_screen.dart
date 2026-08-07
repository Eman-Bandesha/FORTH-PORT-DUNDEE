import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'data/reports_repository.dart';
import 'models/report_models.dart';
import 'widgets/report_donut_chart.dart';
import 'widgets/report_widgets.dart';

/// Category report (design screen 6): stock quantity by category as a donut
/// chart plus a ranked breakdown table.
class CategoryReportScreen extends StatefulWidget {
  const CategoryReportScreen({super.key});

  @override
  State<CategoryReportScreen> createState() => _CategoryReportScreenState();
}

class _CategoryReportScreenState extends State<CategoryReportScreen> {
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
    final List<NamedQuantity> categories = ReportsRepository.byCategory(
      location: _locationFilter,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportCategory),
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
            const SizedBox(height: 22),
            const ReportSectionTitle(AppStrings.stockByCategory),
            const SizedBox(height: 14),
            ReportCard(
              child: ReportDonutChart(
                segments: categories,
                centerLabel: AppStrings.totalQtyShort,
              ),
            ),
            const SizedBox(height: 18),
            ReportCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: RankedQuantityTable(
                segments: categories,
                nameHeader: AppStrings.categoryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
