import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'category_report_screen.dart';
import 'export_reports_screen.dart';
import 'issued_stock_report_screen.dart';
import 'location_report_screen.dart';
import 'low_stock_report_screen.dart';
import 'stock_in_out_report_screen.dart';
import 'stock_summary_report_screen.dart';
import 'widgets/report_widgets.dart';

/// Reports hub (design screen 1): a list of available reports. This is hosted
/// as a primary tab in the app shell.
class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ReportOption> options = <_ReportOption>[
      _ReportOption(
        icon: Icons.summarize_rounded,
        color: AppColors.link,
        title: AppStrings.reportStockSummary,
        subtitle: AppStrings.reportStockSummarySub,
        builder: (_) => const StockSummaryReportScreen(),
      ),
      _ReportOption(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE8A33D),
        title: AppStrings.reportLowStock,
        subtitle: AppStrings.reportLowStockSub,
        builder: (_) => const LowStockReportScreen(),
      ),
      _ReportOption(
        icon: Icons.swap_vert_rounded,
        color: const Color(0xFF1E8E54),
        title: AppStrings.reportStockInOut,
        subtitle: AppStrings.reportStockInOutSub,
        builder: (_) => const StockInOutReportScreen(),
      ),
      _ReportOption(
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.red,
        title: AppStrings.reportIssuedStock,
        subtitle: AppStrings.reportIssuedStockSub,
        builder: (_) => const IssuedStockReportScreen(),
      ),
      _ReportOption(
        icon: Icons.donut_large_rounded,
        color: const Color(0xFF8E5BD0),
        title: AppStrings.reportCategory,
        subtitle: AppStrings.reportCategorySub,
        builder: (_) => const CategoryReportScreen(),
      ),
      _ReportOption(
        icon: Icons.location_on_rounded,
        color: const Color(0xFF12B5C9),
        title: AppStrings.reportLocation,
        subtitle: AppStrings.reportLocationSub,
        builder: (_) => const LocationReportScreen(),
      ),
      _ReportOption(
        icon: Icons.ios_share_rounded,
        color: AppColors.navy,
        title: AppStrings.reportExport,
        subtitle: AppStrings.reportExportSub,
        builder: (_) => const ExportReportsScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportsTitle),
        titleSpacing: 20,
        centerTitle: false,
        actions: const <Widget>[ReportsBell(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (BuildContext context, int index) {
            final _ReportOption option = options[index];
            return _ReportTile(
              option: option,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: option.builder),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportOption {
  const _ReportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.option, required this.onTap});

  final _ReportOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A0A2240),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(option.icon, color: option.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
