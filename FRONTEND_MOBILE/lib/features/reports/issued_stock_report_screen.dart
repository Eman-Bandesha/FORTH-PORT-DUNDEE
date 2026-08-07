import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../movements/models/movement.dart';
import 'data/reports_repository.dart';
import 'widgets/report_widgets.dart';

/// Issued Stock report (design screen 5): stock-out movements with quantity and
/// who requested/issued them.
class IssuedStockReportScreen extends StatefulWidget {
  const IssuedStockReportScreen({super.key});

  @override
  State<IssuedStockReportScreen> createState() =>
      _IssuedStockReportScreenState();
}

class _IssuedStockReportScreenState extends State<IssuedStockReportScreen> {
  DateTimeRange? _range;
  String _person = AppStrings.allPersons;

  String? get _personFilter =>
      _person == AppStrings.allPersons ? null : _person;

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
    final List<Movement> issued = ReportsRepository.issuedMovements(
      person: _personFilter,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.reportIssuedStock),
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
                    label: AppStrings.dateLabelReport,
                    value: reportRangeLabel(_range),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickRange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ReportDropdownField<String>(
                    label: AppStrings.personLabel,
                    value: _person,
                    items: <String>[
                      AppStrings.allPersons,
                      ...ReportsRepository.people,
                    ],
                    labelOf: (String v) => v,
                    onChanged: (String? v) =>
                        setState(() => _person = v ?? AppStrings.allPersons),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ReportMetricTile(
              label: AppStrings.totalIssuedItems,
              value: '${issued.length}',
              icon: Icons.assignment_turned_in_rounded,
              iconColor: AppColors.red,
            ),
            const SizedBox(height: 22),
            ReportCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppStrings.itemHeader,
                            style: _headerStyle,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(AppStrings.qtyHeader, style: _headerStyle),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            AppStrings.issuedToHeader,
                            textAlign: TextAlign.end,
                            style: _headerStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  if (issued.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        AppStrings.noMovementsFound,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (int i = 0; i < issued.length; i++) ...<Widget>[
                      _IssuedRow(movement: issued[i]),
                      if (i != issued.length - 1)
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

const TextStyle _headerStyle = TextStyle(
  color: AppColors.textMuted,
  fontSize: 12.5,
  fontWeight: FontWeight.w700,
);

class _IssuedRow extends StatelessWidget {
  const _IssuedRow({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    movement.image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.fieldFill,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        movement.itemCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${movement.quantity}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              movement.requestedBy,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
