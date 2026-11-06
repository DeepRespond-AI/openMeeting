import 'package:flutter/material.dart';

/// Brand palette — mirrors `frontend/tailwind.config.js` (`brand.*`) and the CSS variables in
/// `frontend/src/app/globals.css` (DEVELOPMENT.md §5). Feature code never uses raw colors:
/// read `context.colors.<token>`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand50,
    required this.brand100,
    required this.brand200,
    required this.brand500,
    required this.brand600,
    required this.brand700,
    required this.brandCyan,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.foreground,
    required this.secondary,
    required this.onSecondary,
    required this.muted,
    required this.mutedForeground,
    required this.tertiary,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.input,
    required this.destructive,
    required this.onDestructive,
    required this.success,
    required this.warning,
    required this.recording,
    required this.brandGradient,
  });

  final Color brand50;
  final Color brand100;
  final Color brand200;
  final Color brand500;
  final Color brand600;
  final Color brand700;
  final Color brandCyan;

  /// `--primary` (brand blue).
  final Color primary;
  final Color onPrimary;

  /// App canvas `--background`.
  final Color background;

  /// Cards, sheets, app bars `--card`.
  final Color surface;

  /// Main text `--foreground`.
  final Color foreground;
  final Color secondary;
  final Color onSecondary;
  final Color muted;

  /// Secondary text `--muted-foreground`.
  final Color mutedForeground;

  /// Tertiary text (tailwind `tertiary`).
  final Color tertiary;

  /// Pale blue hover/selected `--accent`.
  final Color accent;
  final Color onAccent;
  final Color border;
  final Color input;
  final Color destructive;
  final Color onDestructive;
  final Color success;
  final Color warning;

  /// Recording indicator (live dot / record button).
  final Color recording;

  /// `bg-brand-gradient`: 135° #1F55F0 → #22A8FF.
  final LinearGradient brandGradient;

  static const _gradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F55F0), Color(0xFF22A8FF)],
  );

  static const AppColors light = AppColors(
    brand50: Color(0xFFEEF4FF),
    brand100: Color(0xFFDBE7FF),
    brand200: Color(0xFFBFD4FF),
    brand500: Color(0xFF2F6BFF),
    brand600: Color(0xFF1F55F0),
    brand700: Color(0xFF1A44D0),
    brandCyan: Color(0xFF22A8FF),
    primary: Color(0xFF0052D9),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    foreground: Color(0xFF0F172A),
    secondary: Color(0xFFEDEFF3),
    onSecondary: Color(0xFF182543),
    muted: Color(0xFFF0F1F5),
    mutedForeground: Color(0xFF6B7280),
    tertiary: Color(0xFF64748B),
    accent: Color(0xFFEBF3FF),
    onAccent: Color(0xFF1450D2),
    border: Color(0xFFE2E6EE),
    input: Color(0xFFDCDFE5),
    destructive: Color(0xFFDC2626),
    onDestructive: Color(0xFFFFFFFF),
    success: Color(0xFF29A36A),
    warning: Color(0xFFF59E0B),
    recording: Color(0xFFDC2626),
    brandGradient: _gradientLight,
  );

  /// Reasonable dark variant (the desktop app has no dark theme).
  static const AppColors dark = AppColors(
    brand50: Color(0xFF16213F),
    brand100: Color(0xFF1C2A52),
    brand200: Color(0xFF243670),
    brand500: Color(0xFF5F8EFF),
    brand600: Color(0xFF2F6BFF),
    brand700: Color(0xFF93B6FF),
    brandCyan: Color(0xFF22A8FF),
    primary: Color(0xFF3B82F6),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFF1E1F21),
    surface: Color(0xFF28292B),
    foreground: Color(0xFFE5E9F0),
    secondary: Color(0xFF1E293B),
    onSecondary: Color(0xFFE2E8F0),
    muted: Color(0xFF1A2235),
    mutedForeground: Color(0xFF94A3B8),
    tertiary: Color(0xFF8391A7),
    accent: Color(0xFF1C2A52),
    onAccent: Color(0xFF93B6FF),
    border: Color(0xFF263045),
    input: Color(0xFF2D3850),
    destructive: Color(0xFFEF4444),
    onDestructive: Color(0xFFFFFFFF),
    success: Color(0xFF34C17E),
    warning: Color(0xFFFBBF24),
    recording: Color(0xFFEF4444),
    brandGradient: _gradientLight,
  );

  @override
  AppColors copyWith({
    Color? brand50,
    Color? brand100,
    Color? brand200,
    Color? brand500,
    Color? brand600,
    Color? brand700,
    Color? brandCyan,
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? foreground,
    Color? secondary,
    Color? onSecondary,
    Color? muted,
    Color? mutedForeground,
    Color? tertiary,
    Color? accent,
    Color? onAccent,
    Color? border,
    Color? input,
    Color? destructive,
    Color? onDestructive,
    Color? success,
    Color? warning,
    Color? recording,
    LinearGradient? brandGradient,
  }) => AppColors(
    brand50: brand50 ?? this.brand50,
    brand100: brand100 ?? this.brand100,
    brand200: brand200 ?? this.brand200,
    brand500: brand500 ?? this.brand500,
    brand600: brand600 ?? this.brand600,
    brand700: brand700 ?? this.brand700,
    brandCyan: brandCyan ?? this.brandCyan,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    foreground: foreground ?? this.foreground,
    secondary: secondary ?? this.secondary,
    onSecondary: onSecondary ?? this.onSecondary,
    muted: muted ?? this.muted,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    tertiary: tertiary ?? this.tertiary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    border: border ?? this.border,
    input: input ?? this.input,
    destructive: destructive ?? this.destructive,
    onDestructive: onDestructive ?? this.onDestructive,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    recording: recording ?? this.recording,
    brandGradient: brandGradient ?? this.brandGradient,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brand50: c(brand50, other.brand50),
      brand100: c(brand100, other.brand100),
      brand200: c(brand200, other.brand200),
      brand500: c(brand500, other.brand500),
      brand600: c(brand600, other.brand600),
      brand700: c(brand700, other.brand700),
      brandCyan: c(brandCyan, other.brandCyan),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      foreground: c(foreground, other.foreground),
      secondary: c(secondary, other.secondary),
      onSecondary: c(onSecondary, other.onSecondary),
      muted: c(muted, other.muted),
      mutedForeground: c(mutedForeground, other.mutedForeground),
      tertiary: c(tertiary, other.tertiary),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      border: c(border, other.border),
      input: c(input, other.input),
      destructive: c(destructive, other.destructive),
      onDestructive: c(onDestructive, other.onDestructive),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      recording: c(recording, other.recording),
      brandGradient: LinearGradient.lerp(brandGradient, other.brandGradient, t)!,
    );
  }
}
