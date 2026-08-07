import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'models/movement.dart';

/// Read-only detail view for a single [Movement] (design screen 4).
class MovementDetailsScreen extends StatelessWidget {
  const MovementDetailsScreen({super.key, required this.movement});

  final Movement movement;

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label — ${AppStrings.comingSoon}')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final String unit = movement.unit;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.movementDetailsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share',
            onPressed: () => _comingSoon(context, 'Share'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: <Widget>[
            _Header(movement: movement),
            const SizedBox(height: 22),
            _SectionLabel(AppStrings.detailsSection),
            const SizedBox(height: 10),
            _Card(
              children: <Widget>[
                _DetailRow(
                  label: AppStrings.referenceNoLabel,
                  value: movement.referenceNo,
                ),
                _DetailRow(
                  label: AppStrings.fromLocationLabel,
                  value: movement.location,
                ),
                _DetailRow(
                  label: AppStrings.totalQuantityLabel,
                  value: '${movement.quantity} $unit',
                ),
                _DetailRow(
                  label: AppStrings.notesLabel,
                  value: movement.notes,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionLabel(AppStrings.stockInformation),
            const SizedBox(height: 10),
            _Card(
              children: <Widget>[
                _DetailRow(
                  label: AppStrings.stockBeforeMovement,
                  value: '${movement.stockBefore} $unit',
                ),
                _DetailRow(
                  label: movement.isIn
                      ? AppStrings.stockMovedIn
                      : AppStrings.stockMovedOut,
                  value: '${movement.quantity} $unit',
                  valueColor: movement.type.color,
                ),
                _DetailRow(
                  label: AppStrings.remainingStock,
                  value: '${movement.remainingStock} $unit',
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final Color color = movement.type.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            movement.type.label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                movement.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.fieldFill,
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    movement.itemName,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    movement.itemCode,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              movement.changeLabel,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          movement.dateTimeLabel,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
