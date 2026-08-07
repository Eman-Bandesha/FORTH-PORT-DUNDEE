import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../items/data/items_repository.dart';
import '../../items/models/item.dart';
import '../../items/models/item_filters.dart';
import '../../notifications/notifications_screen.dart';
import '../models/report_models.dart';

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// A short label for a report date range (defaults to a sample week).
String reportRangeLabel(DateTimeRange? range) {
  final DateTimeRange r =
      range ?? DateTimeRange(start: DateTime(2024, 5, 13), end: DateTime(2024, 5, 20));
  return '${_fmt(r.start)} – ${_fmt(r.end)} ${r.end.year}';
}

/// Shared colour palette for report charts (category/location segments).
const List<Color> kReportPalette = <Color>[
  AppColors.link,
  Color(0xFF1E8E54),
  Color(0xFFE8A33D),
  Color(0xFF8E5BD0),
  AppColors.red,
  Color(0xFF12B5C9),
  Color(0xFFEA6F9E),
];

/// Bold section heading used between report blocks.
class ReportSectionTitle extends StatelessWidget {
  const ReportSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// White rounded card container for report content blocks.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
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
      child: child,
    );
  }
}

/// A compact metric tile (label + value + optional icon).
class ReportMetricTile extends StatelessWidget {
  const ReportMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor = AppColors.navy,
    this.iconColor = AppColors.link,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color valueColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled, tappable filter box (e.g. a date range trigger).
class ReportFilterField extends StatelessWidget {
  const ReportFilterField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Labelled dropdown styled to match the report filter fields.
class ReportDropdownField<T> extends StatelessWidget {
  const ReportDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.navy, width: 1.5),
            border: _border(AppColors.border),
          ),
          items: items
              .map(
                (T item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelOf(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// A ranked breakdown table: Rank | Name | Quantity | %.
class RankedQuantityTable extends StatelessWidget {
  const RankedQuantityTable({
    super.key,
    required this.segments,
    required this.nameHeader,
  });

  final List<NamedQuantity> segments;
  final String nameHeader;

  static const TextStyle _header = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final int total = segments.fold<int>(
      0,
      (int sum, NamedQuantity s) => sum + s.quantity,
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 40, child: Text(AppStrings.rankHeader, style: _header)),
              Expanded(child: Text(nameHeader, style: _header)),
              const SizedBox(
                width: 70,
                child: Text(AppStrings.quantityHeader, style: _header),
              ),
              const SizedBox(
                width: 50,
                child: Text(
                  AppStrings.percentHeader,
                  textAlign: TextAlign.end,
                  style: _header,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        if (segments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              AppStrings.noItemsFound,
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          for (int i = 0; i < segments.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: kReportPalette[i % kReportPalette.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      segments[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${segments[i].quantity}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      total == 0
                          ? '0%'
                          : '${(segments[i].quantity / total * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != segments.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
      ],
    );
  }
}

/// Notification bell with an alert badge for report screen app bars.
class ReportsBell extends StatelessWidget {
  const ReportsBell({super.key});

  int _alertCount() {
    int count = 0;
    for (final StockStatus status in <StockStatus>[
      StockStatus.lowStock,
      StockStatus.outOfStock,
    ]) {
      count += ItemsRepository.query(
        filters: ItemFilters(statuses: <StockStatus>{status}),
      ).length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final int count = _alertCount();
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: AppStrings.notificationsTitle,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.navy, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
