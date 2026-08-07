import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'data/items_repository.dart';
import 'models/item.dart';
import 'widgets/stock_status_badge.dart';

/// Edit form for an [Item]. On save it updates the repository and returns the
/// updated item via `Navigator.pop`.
class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _unit;
  late final TextEditingController _reorder;
  late final TextEditingController _description;
  late String _category;
  late String _location;

  @override
  void initState() {
    super.initState();
    final Item i = widget.item;
    _name = TextEditingController(text: i.name);
    _code = TextEditingController(text: i.code);
    _unit = TextEditingController(text: i.unit);
    _reorder = TextEditingController(text: '${i.reorderLevel}');
    _description = TextEditingController(text: i.description);
    _category = i.category;
    _location = i.location;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _unit.dispose();
    _reorder.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final Item updated = widget.item.copyWith(
      name: _name.text.trim(),
      code: _code.text.trim(),
      unit: _unit.text.trim(),
      reorderLevel:
          int.tryParse(_reorder.text.trim()) ?? widget.item.reorderLevel,
      description: _description.text.trim(),
      category: _category,
      location: _location,
    );
    await ItemsRepository.update(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.editItemTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: <Widget>[
            _ItemHeader(item: widget.item),
            const SizedBox(height: 22),
            _Field(
              label: AppStrings.itemNameLabel,
              controller: _name,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            _Field(label: AppStrings.skuLabel, controller: _code),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _DropdownField(
                    label: AppStrings.categoryLabel,
                    value: _category,
                    items: ItemsRepository.categories,
                    onChanged: (String v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Field(
                    label: AppStrings.detailUnit,
                    controller: _unit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Field(
              label: AppStrings.detailReorderLevel,
              controller: _reorder,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),
            _DropdownField(
              label: AppStrings.locationLabel,
              value: _location,
              items: ItemsRepository.locations,
              onChanged: (String v) => setState(() => _location = v),
            ),
            const SizedBox(height: 16),
            _Field(
              label: AppStrings.detailDescription,
              controller: _description,
              maxLines: 3,
              required: false,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
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
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.saveChanges,
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

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            item.image,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 64,
              height: 64,
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
                item.name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.code,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              StockStatusBadge(status: item.status),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.required = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool required;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Label(text: label, required: required),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          validator: required
              ? (String? v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.fieldRequired
                    : null
              : null,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Label(text: label, required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(),
          items: items
              .map(
                (String v) =>
                    DropdownMenuItem<String>(value: v, child: Text(v)),
              )
              .toList(),
          onChanged: (String? v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.required});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        children: <InlineSpan>[
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    filled: true,
    fillColor: AppColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.navy, width: 1.5),
    errorBorder: border(AppColors.red),
    focusedErrorBorder: border(AppColors.red, width: 1.5),
  );
}
