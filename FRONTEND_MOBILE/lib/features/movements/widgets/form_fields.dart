import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A field label with an optional red required asterisk, followed by [child].
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
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
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// A read-only, tappable box (used for the date picker trigger).
class TapField extends StatelessWidget {
  const TapField({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// A labelled dropdown styled to match the rest of the app's form fields.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.required = false,
    this.errorText,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool required;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      required: required,
      child: DropdownButtonFormField<T>(
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
          errorText: errorText,
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.navy, width: 1.5),
          border: _border(AppColors.border),
          errorBorder: _border(AppColors.red),
          focusedErrorBorder: _border(AppColors.red, width: 1.5),
        ),
        items: items
            .map(
              (T item) =>
                  DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
