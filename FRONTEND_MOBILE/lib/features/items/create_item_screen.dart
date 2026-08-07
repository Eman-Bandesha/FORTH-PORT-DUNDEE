import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import 'data/items_repository.dart';
import 'models/item.dart';

/// Form for creating a brand-new inventory [Item]. On save it adds the item to
/// the repository and returns it via `Navigator.pop`.
class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _unit = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _reorder = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String? _category;
  String? _location;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _unit.dispose();
    _quantity.dispose();
    _reorder.dispose();
    _description.dispose();
    super.dispose();
  }

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _now() {
    final DateTime d = DateTime.now();
    final int hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String period = d.hour < 12 ? 'AM' : 'PM';
    final String minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $hour12:$minute $period';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final int quantity = int.tryParse(_quantity.text.trim()) ?? 0;
    final int reorder = int.tryParse(_reorder.text.trim()) ?? 0;

    final Item item = Item(
      code: _code.text.trim(),
      name: _name.text.trim(),
      image: '',
      status: ItemsRepository.statusFor(
        quantity: quantity,
        reorderLevel: reorder,
      ),
      quantity: quantity,
      category: _category ?? '',
      unit: _unit.text.trim(),
      reorderLevel: reorder,
      location: _location ?? '',
      description: _description.text.trim(),
      lastUpdated: _now(),
    );

    try {
      if (await ItemsRepository.codeExists(item.code)) {
        if (mounted) {
          AppSnackBar.error(context, AppStrings.codeAlreadyExists);
        }
        return;
      }
      await ItemsRepository.add(item);
      if (mounted) Navigator.of(context).pop(item);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, AppStrings.comingSoon);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.createItemTitle),
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
            _PhotoPicker(
              onTap: () => AppSnackBar.success(
                context,
                '${AppStrings.addPhotoLabel} — ${AppStrings.comingSoon}',
              ),
            ),
            const SizedBox(height: 22),
            _Field(
              label: AppStrings.itemNameLabel,
              controller: _name,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _Field(
              label: AppStrings.skuLabel,
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              validator: (String? v) {
                final String value = (v ?? '').trim();
                if (value.isEmpty) return AppStrings.fieldRequired;
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _DropdownField(
                    label: AppStrings.categoryLabel,
                    value: _category,
                    hint: AppStrings.selectCategoryHint,
                    items: ItemsRepository.categories,
                    onChanged: (String v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Field(
                    label: AppStrings.detailUnit,
                    controller: _unit,
                    hintText: AppStrings.unitHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _Field(
                    label: AppStrings.initialStockLabel,
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _Field(
                    label: AppStrings.detailReorderLevel,
                    controller: _reorder,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DropdownField(
              label: AppStrings.locationLabel,
              value: _location,
              hint: AppStrings.selectLocationHint,
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
                    AppStrings.saveItemCta,
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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.navy,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.addPhotoLabel,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
    this.hintText,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool required;
  final String? hintText;
  final FormFieldValidator<String>? validator;
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
          validator:
              validator ??
              (required
                  ? (String? v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.fieldRequired
                        : null
                  : null),
          decoration: _inputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
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
          initialValue: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
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
          validator: (String? v) =>
              (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
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

InputDecoration _inputDecoration({String? hintText}) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    filled: true,
    fillColor: AppColors.fieldFill,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.navy, width: 1.5),
    errorBorder: border(AppColors.red),
    focusedErrorBorder: border(AppColors.red, width: 1.5),
  );
}
