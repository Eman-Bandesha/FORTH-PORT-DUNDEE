import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// A styled, validated text field used across the authentication screens.
///
/// Encapsulates the rounded, lightly-filled look from the design along with a
/// leading icon and an optional trailing widget (e.g. password visibility
/// toggle), keeping the screen code declarative and consistent.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borderOf(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
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
        prefixIcon: Icon(prefixIcon, color: AppColors.textMuted, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: borderOf(AppColors.border),
        focusedBorder: borderOf(AppColors.navy, width: 1.6),
        errorBorder: borderOf(AppColors.red),
        focusedErrorBorder: borderOf(AppColors.red, width: 1.6),
      ),
    );
  }
}
