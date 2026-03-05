import 'package:flutter/material.dart';

/// Static palette — same in light and dark mode.
class AppPalette {
  AppPalette._();

  static const accent = Color(0xFF7C3AED);
  static const accentLight = Color(0xFFA855F7);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  static const cyan = Color(0xFF06B6D4);
  static const pink = Color(0xFFEC4899);
}

/// Dynamic palette — adapts to light / dark theme.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.card,
    required this.input,
    required this.text,
    required this.textSub,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.gradientEnd,
    required this.shimmer,
  });

  final Color bg;          // scaffold background
  final Color card;        // card / appBar background
  final Color input;       // text field fill / inner container
  final Color text;        // primary text
  final Color textSub;     // secondary text (was grey[300-400])
  final Color textHint;    // hint / tertiary text (was grey[500-600])
  final Color border;      // card borders
  final Color divider;     // list dividers
  final Color gradientEnd; // end-stop for time-based home gradients
  final Color shimmer;     // skeleton / shimmer color

  static const dark = AppColors(
    bg: Color(0xFF0F0F1E),
    card: Color(0xFF1A1A2E),
    input: Color(0xFF0F0F1E),
    text: Color(0xFFFFFFFF),
    textSub: Color(0xFFD1D5DB),   // ~grey-300
    textHint: Color(0xFF9CA3AF),  // ~grey-400
    border: Color(0x14FFFFFF),    // white 8%
    divider: Color(0xFF2A2A3E),
    gradientEnd: Color(0xFF0F0F1E),
    shimmer: Color(0xFF2A2A3E),
  );

  static const light = AppColors(
    bg: Color(0xFFF0F2F8),
    card: Color(0xFFFFFFFF),
    input: Color(0xFFF5F5F7),
    text: Color(0xFF1A1A2E),
    textSub: Color(0xFF374151),   // ~grey-700
    textHint: Color(0xFF6B7280),  // ~grey-500
    border: Color(0x14000000),    // black 8%
    divider: Color(0xFFE5E7EB),
    gradientEnd: Color(0xFFF0F2F8),
    shimmer: Color(0xFFE5E7EB),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? card,
    Color? input,
    Color? text,
    Color? textSub,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? gradientEnd,
    Color? shimmer,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      input: input ?? this.input,
      text: text ?? this.text,
      textSub: textSub ?? this.textSub,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      input: Color.lerp(input, other.input, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
