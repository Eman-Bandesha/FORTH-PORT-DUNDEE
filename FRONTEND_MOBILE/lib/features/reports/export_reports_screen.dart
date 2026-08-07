import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import 'data/reports_repository.dart';
import 'widgets/report_widgets.dart';

enum _ExportFormat { pdf, excel, csv }

extension _FormatX on _ExportFormat {
  String get label => switch (this) {
    _ExportFormat.pdf => AppStrings.formatPdf,
    _ExportFormat.excel => AppStrings.formatExcel,
    _ExportFormat.csv => AppStrings.formatCsv,
  };

  IconData get icon => switch (this) {
    _ExportFormat.pdf => Icons.picture_as_pdf_rounded,
    _ExportFormat.excel => Icons.table_chart_rounded,
    _ExportFormat.csv => Icons.description_rounded,
  };

  Color get color => switch (this) {
    _ExportFormat.pdf => AppColors.red,
    _ExportFormat.excel => const Color(0xFF1E8E54),
    _ExportFormat.csv => AppColors.link,
  };
}

/// Export Reports (design screen 7): pick a report type, range, location and
/// format, then preview / export / share.
class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  static const List<String> _reportTypes = <String>[
    AppStrings.reportStockSummary,
    AppStrings.reportLowStock,
    AppStrings.reportStockInOut,
    AppStrings.reportIssuedStock,
    AppStrings.reportCategory,
    AppStrings.reportLocation,
  ];

  String _reportType = _reportTypes.first;
  DateTimeRange? _range;
  String _location = AppStrings.allLocations;
  _ExportFormat _format = _ExportFormat.pdf;
  bool _ready = false;

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  void _export() {
    setState(() => _ready = true);
    AppSnackBar.success(
      context,
      '$_reportType ${_format.label} ${AppStrings.reportReadyTitle.toLowerCase()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportExport),
        actions: const <Widget>[ReportsBell(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: <Widget>[
            ReportDropdownField<String>(
              label: AppStrings.reportTypeLabel,
              value: _reportType,
              items: _reportTypes,
              labelOf: (String v) => v,
              onChanged: (String? v) => setState(() {
                _reportType = v ?? _reportTypes.first;
                _ready = false;
              }),
            ),
            const SizedBox(height: 16),
            ReportFilterField(
              label: AppStrings.dateRangeLabelReport,
              value: reportRangeLabel(_range),
              icon: Icons.calendar_today_rounded,
              onTap: _pickRange,
            ),
            const SizedBox(height: 16),
            ReportDropdownField<String>(
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
            const SizedBox(height: 20),
            const Text(
              AppStrings.formatLabel,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                for (final _ExportFormat f in _ExportFormat.values) ...<Widget>[
                  Expanded(
                    child: _FormatCard(
                      format: f,
                      selected: _format == f,
                      onTap: () => setState(() => _format = f),
                    ),
                  ),
                  if (f != _ExportFormat.values.last)
                    const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AppSnackBar.success(
                      context,
                      '${AppStrings.previewCta} — ${AppStrings.comingSoon}',
                    ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text(AppStrings.previewCta),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text(AppStrings.exportCta),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_ready) ...<Widget>[
              const SizedBox(height: 22),
              _ReadyCard(
                onShare: () => AppSnackBar.success(
                  context,
                  '${AppStrings.shareReportCta} — ${AppStrings.comingSoon}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final _ExportFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? format.color.withValues(alpha: 0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? format.color : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(format.icon, color: format.color, size: 28),
            const SizedBox(height: 8),
            Text(
              format.label,
              style: TextStyle(
                color: selected ? format.color : AppColors.navy,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB6E0C7)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF1E8E54),
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text(
            AppStrings.reportReadyTitle,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.reportReadyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded),
              label: const Text(AppStrings.shareReportCta),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8E54),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
