import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Qualitative password strength, derived from length and character variety.
enum PasswordStrength {
  none,
  weak,
  fair,
  good,
  strong;

  /// Scores a password from [none] to [strong] using simple, transparent rules.
  static PasswordStrength of(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    return switch (score) {
      <= 1 => PasswordStrength.weak,
      2 => PasswordStrength.fair,
      3 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }

  /// Number of filled segments (out of four).
  int get filledSegments => switch (this) {
    PasswordStrength.none => 0,
    PasswordStrength.weak => 1,
    PasswordStrength.fair => 2,
    PasswordStrength.good => 3,
    PasswordStrength.strong => 4,
  };

  String get label => switch (this) {
    PasswordStrength.none => '',
    PasswordStrength.weak => AppStrings.strengthWeak,
    PasswordStrength.fair => AppStrings.strengthFair,
    PasswordStrength.good => AppStrings.strengthGood,
    PasswordStrength.strong => AppStrings.strengthStrong,
  };

  Color get color => switch (this) {
    PasswordStrength.none => AppColors.border,
    PasswordStrength.weak => const Color(0xFFE1251B),
    PasswordStrength.fair => const Color(0xFFE8A33D),
    PasswordStrength.good => const Color(0xFF4CAF50),
    PasswordStrength.strong => const Color(0xFF22B573),
  };
}

/// A four-segment strength bar with a trailing strength label.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: List<Widget>.generate(4, (int i) {
                final bool filled = i < strength.filledSegments;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: filled ? strength.color : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            strength.label,
            style: TextStyle(
              color: strength.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
