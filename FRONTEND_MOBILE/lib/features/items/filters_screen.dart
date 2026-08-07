import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'data/items_repository.dart';
import 'models/item.dart';
import 'models/item_filters.dart';

/// Full-screen filter editor. Returns the chosen [ItemFilters] via
/// `Navigator.pop`, or `null` when cancelled.
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.initial});

  final ItemFilters initial;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late Set<StockStatus> _statuses;
  late String? _category;
  late String? _location;
  late ItemSort _sort;

  @override
  void initState() {
    super.initState();
    _statuses = <StockStatus>{...widget.initial.statuses};
    _category = widget.initial.category;
    _location = widget.initial.location;
    _sort = widget.initial.sort;
  }

  void _reset() {
    setState(() {
      _statuses = <StockStatus>{};
      _category = null;
      _location = null;
      _sort = ItemSort.nameAsc;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      ItemFilters(
        statuses: _statuses,
        category: _category,
        location: _location,
        sort: _sort,
      ),
    );
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
          const _SectionLabel(AppStrings.stockStatusLabel),
          const SizedBox(height: 8),
          ...StockStatus.values.map(
            (StockStatus status) => _StatusCheckbox(
              status: status,
              checked: _statuses.contains(status),
              onChanged: (bool value) => setState(() {
                value ? _statuses.add(status) : _statuses.remove(status);
              }),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel(AppStrings.categoryLabel),
          const SizedBox(height: 8),
          _DropdownField<String>(
            hint: AppStrings.selectCategory,
            value: _category,
            items: ItemsRepository.categories,
            labelOf: (String v) => v,
            onChanged: (String? v) => setState(() => _category = v),
          ),
          const SizedBox(height: 22),
          const _SectionLabel(AppStrings.locationLabel),
          const SizedBox(height: 8),
          _DropdownField<String>(
            hint: AppStrings.selectLocation,
            value: _location,
            items: ItemsRepository.locations,
            labelOf: (String v) => v,
            onChanged: (String? v) => setState(() => _location = v),
          ),
          const SizedBox(height: 22),
          const _SectionLabel(AppStrings.sortByLabel),
          const SizedBox(height: 8),
          _DropdownField<ItemSort>(
            hint: AppStrings.sortNameAsc,
            value: _sort,
            items: ItemSort.values,
            labelOf: (ItemSort v) => v.label,
            allowClear: false,
            onChanged: (ItemSort? v) =>
                setState(() => _sort = v ?? ItemSort.nameAsc),
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
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.cancel,
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
                  onPressed: _apply,
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

class _StatusCheckbox extends StatelessWidget {
  const _StatusCheckbox({
    required this.status,
    required this.checked,
    required this.onChanged,
  });

  final StockStatus status;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged: (bool? v) => onChanged(v ?? false),
                activeColor: AppColors.navy,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              status.label,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
