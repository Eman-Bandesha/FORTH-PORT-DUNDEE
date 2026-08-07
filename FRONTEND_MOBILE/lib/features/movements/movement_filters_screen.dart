import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'data/movements_repository.dart';
import 'models/movement.dart';
import 'models/movement_filters.dart';

/// Full-screen filter editor for the movements list (design screen 5).
///
/// Returns the chosen [MovementFilters] via `Navigator.pop`, or `null` when
/// dismissed without applying.
class MovementFiltersScreen extends StatefulWidget {
  const MovementFiltersScreen({super.key, required this.initial});

  final MovementFilters initial;

  @override
  State<MovementFiltersScreen> createState() => _MovementFiltersScreenState();
}

class _MovementFiltersScreenState extends State<MovementFiltersScreen> {
  late MovementType _type;
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late String? _location;
  late MovementSort _sort;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type ?? MovementType.stockOut;
    _fromDate = widget.initial.fromDate;
    _toDate = widget.initial.toDate;
    _location = widget.initial.location;
    _sort = widget.initial.sort;
  }

  MovementFilters get _current => MovementFilters(
    type: _type,
    fromDate: _fromDate,
    toDate: _toDate,
    location: _location,
    sort: _sort,
  );

  void _reset() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _location = null;
      _sort = MovementSort.newestFirst;
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final DateTime initial =
        (isFrom ? _fromDate : _toDate) ?? DateTime(2024, 5, 20);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.filtersTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _reset,
            style: TextButton.styleFrom(foregroundColor: AppColors.white),
            child: const Text(
              AppStrings.reset,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        children: <Widget>[
          const _SectionLabel(AppStrings.dateRangeLabel),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _DateField(
                  label: AppStrings.fromDateLabel,
                  value: _fromDate,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DateField(
                  label: AppStrings.toDateLabel,
                  value: _toDate,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(AppStrings.locationLabel),
          const SizedBox(height: 8),
          _DropdownField<String>(
            hint: AppStrings.selectLocation,
            value: _location,
            items: MovementsRepository.locations,
            labelOf: (String v) => v,
            onChanged: (String? v) => setState(() => _location = v),
          ),
          const SizedBox(height: 22),
          const _SectionLabel(AppStrings.sortByLabel),
          const SizedBox(height: 8),
          _DropdownField<MovementSort>(
            hint: AppStrings.sortNewestFirst,
            value: _sort,
            items: MovementSort.values,
            labelOf: (MovementSort v) => v.label,
            allowClear: false,
            onChanged: (MovementSort? v) =>
                setState(() => _sort = v ?? MovementSort.newestFirst),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(MovementFilters(type: _type)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.clear,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_current),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.applyFilters,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    hasValue
                        ? Movement.formatDate(value!)
                        : AppStrings.selectDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue ? AppColors.navy : AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.allowClear = true,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
      ),
      hint: Text(
        hint,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
      ),
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.navy, width: 1.5),
        border: _border(AppColors.border),
      ),
      items: <DropdownMenuItem<T>>[
        if (allowClear)
          DropdownMenuItem<T>(
            value: null,
            child: Text(
              hint,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ...items.map(
          (T item) =>
              DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
        ),
      ],
      onChanged: onChanged,
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
