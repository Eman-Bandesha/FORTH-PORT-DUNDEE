import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'data/reports_repository.dart';
import 'models/report_models.dart';
import 'widgets/report_donut_chart.dart';
import 'widgets/report_widgets.dart';

/// Location report: stock quantity by warehouse/location as a donut chart plus
/// a ranked breakdown table.
class LocationReportScreen extends StatefulWidget {
  const LocationReportScreen({super.key});

  @override
  State<LocationReportScreen> createState() => _LocationReportScreenState();
}

class _LocationReportScreenState extends State<LocationReportScreen> {
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
    final List<NamedQuantity> locations = ReportsRepository.byLocation();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportLocation),
        actions: const <Widget>[ReportsBell(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: <Widget>[
            ReportFilterField(
              label: AppStrings.dateRangeLabelReport,
              value: reportRangeLabel(_range),
              icon: Icons.calendar_today_rounded,
              onTap: _pickRange,
            ),
            const SizedBox(height: 22),
            const ReportSectionTitle(AppStrings.stockByLocation),
            const SizedBox(height: 14),
            ReportCard(
              child: ReportDonutChart(
                segments: locations,
                centerLabel: AppStrings.totalQtyShort,
              ),
            ),
            const SizedBox(height: 18),
            ReportCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: RankedQuantityTable(
                segments: locations,
                nameHeader: AppStrings.locationHeaderReport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
