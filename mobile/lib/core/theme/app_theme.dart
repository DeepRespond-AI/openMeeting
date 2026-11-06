import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 themes built from the design tokens (DEVELOPMENT.md §5).
/// Fonts: system (PingFang SC on iOS, Noto Sans CJK on Android) — no custom family.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(brightness: Brightness.light, colors: AppColors.light, shadows: AppShadows.light);

  static ThemeData dark() =>
      _build(brightness: Brightness.dark, colors: AppColors.dark, shadows: AppShadows.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required AppShadows shadows,
  }) {
    const spacing = AppSpacing.standard;
    const radius = AppRadius.standard;
    const sizes = AppSizes.standard;

    final scheme = ColorScheme.fromSeed(seedColor: colors.primary, brightness: brightness).copyWith(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.accent,
      onPrimaryContainer: colors.onAccent,
      secondary: colors.brandCyan,
      onSecondary: colors.onPrimary,
      secondaryContainer: colors.secondary,
      onSecondaryContainer: colors.onSecondary,
      tertiary: colors.tertiary,
      error: colors.destructive,
      onError: colors.onDestructive,
      surface: colors.surface,
      onSurface: colors.foreground,
      onSurfaceVariant: colors.mutedForeground,
      surfaceContainerLowest: colors.surface,
      surfaceContainerLow: colors.background,
      surfaceContainer: colors.muted,
      surfaceContainerHigh: colors.secondary,
      outline: colors.input,
      outlineVariant: colors.border,
    );

    final shape = RoundedRectangleBorder(borderRadius: radius.mdAll);
    final buttonSize = Size(sizes.touchTarget, sizes.buttonHeight);
    final buttonPadding = EdgeInsets.symmetric(horizontal: spacing.lg);

    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: radius.mdAll,
      borderSide: BorderSide(color: color, width: sizes.borderWidth),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      extensions: [colors, spacing, radius, sizes, shadows],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: colors.border, width: sizes.borderWidth),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius.mdAll,
          side: BorderSide(color: colors.border, width: sizes.borderWidth),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: sizes.borderWidth, space: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: shape,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: shape,
          foregroundColor: colors.foreground,
          side: BorderSide(color: colors.border, width: sizes.borderWidth),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape, foregroundColor: colors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
        border: inputBorder(colors.input),
        enabledBorder: inputBorder(colors.input),
        focusedBorder: inputBorder(colors.primary),
        errorBorder: inputBorder(colors.destructive),
        focusedErrorBorder: inputBorder(colors.destructive),
        hintStyle: TextStyle(color: colors.mutedForeground),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.mutedForeground,
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.md),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius.pillAll),
        side: BorderSide(color: colors.border, width: sizes.borderWidth),
        selectedColor: colors.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius.mdAll),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius.lgAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius.lg)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: radius.lgAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
    );
  }
}
