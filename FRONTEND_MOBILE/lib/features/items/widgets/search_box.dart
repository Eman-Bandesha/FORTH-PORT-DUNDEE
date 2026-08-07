import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A pill-shaped search input.
///
/// When [readOnly] is true it behaves as a button (used on the Items list to
/// open the dedicated search screen); otherwise it's a live search field.
class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onClear,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final bool hasText = (controller?.text ?? '').isNotEmpty;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      autofocus: autofocus,
      onTap: onTap,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 22,
        ),
        suffixIcon: hasText && !readOnly
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'Clear',
              )
            : null,
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.navy, width: 1.5),
        border: _border(AppColors.border),
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
