import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

double _l(double a, double b, double t) => lerpDouble(a, b, t)!;

/// Spacing scale (DEVELOPMENT.md §5): 4 / 8 / 12 / 16 / 20 / 24 / 32. Access: `context.spacing`.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xxs = 4,
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 20,
    this.xl = 24,
    this.xxl = 32,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  static const AppSpacing standard = AppSpacing();

  /// Default page padding (horizontal [md], vertical [md]).
  EdgeInsets get page => EdgeInsets.all(md);

  /// Horizontal page gutter only.
  EdgeInsets get pageHorizontal => EdgeInsets.symmetric(horizontal: md);

  /// Padding inside cards.
  EdgeInsets get card => EdgeInsets.all(md);

  /// Vertical gap widgets.
  SizedBox get gapXs => SizedBox(height: xs, width: xs);
  SizedBox get gapSm => SizedBox(height: sm, width: sm);
  SizedBox get gapMd => SizedBox(height: md, width: md);
  SizedBox get gapLg => SizedBox(height: lg, width: lg);
  SizedBox get gapXl => SizedBox(height: xl, width: xl);

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) => AppSpacing(
    xxs: xxs ?? this.xxs,
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xxl: xxl ?? this.xxl,
  );

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      xxs: _l(xxs, other.xxs, t),
      xs: _l(xs, other.xs, t),
      sm: _l(sm, other.sm, t),
      md: _l(md, other.md, t),
      lg: _l(lg, other.lg, t),
      xl: _l(xl, other.xl, t),
      xxl: _l(xxl, other.xxl, t),
    );
  }
}

/// Corner radii (DEVELOPMENT.md §5): sm 8, md 12 (= desktop `--radius`), lg 16, pill 999.
/// Access: `context.radius`.
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({this.sm = 8, this.md = 12, this.lg = 16, this.pill = 999});

  final double sm;
  final double md;
  final double lg;
  final double pill;

  static const AppRadius standard = AppRadius();

  BorderRadius get smAll => BorderRadius.circular(sm);
  BorderRadius get mdAll => BorderRadius.circular(md);
  BorderRadius get lgAll => BorderRadius.circular(lg);
  BorderRadius get pillAll => BorderRadius.circular(pill);

  @override
  AppRadius copyWith({double? sm, double? md, double? lg, double? pill}) =>
      AppRadius(sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg, pill: pill ?? this.pill);

  @override
  AppRadius lerp(covariant AppRadius? other, double t) {
    if (other == null) return this;
    return AppRadius(
      sm: _l(sm, other.sm, t),
      md: _l(md, other.md, t),
      lg: _l(lg, other.lg, t),
      pill: _l(pill, other.pill, t),
    );
  }
}

/// Fixed widget geometry (icon boxes, button heights, logo sizes). Access: `context.sizes`.
@immutable
class AppSizes extends ThemeExtension<AppSizes> {
  const AppSizes({
    this.iconSm = 16,
    this.iconMd = 20,
    this.iconLg = 24,
    this.iconXl = 32,
    this.touchTarget = 44,
    this.buttonHeight = 48,
    this.logoSm = 28,
    this.logoLg = 72,
    this.recordButton = 72,
    this.maxContentWidth = 640,
    this.borderWidth = 1,
    this.notesMaxHeight = 200,
  });

  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;
  final double touchTarget;
  final double buttonHeight;

  /// Brand logo height in app bars / on splash & login.
  final double logoSm;
  final double logoLg;
  final double recordButton;

  /// Max width of centered content on tablets.
  final double maxContentWidth;
  final double borderWidth;

  /// Max height of scrollable release notes (update dialog / page).
  final double notesMaxHeight;

  static const AppSizes standard = AppSizes();

  @override
  AppSizes copyWith({
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? iconXl,
    double? touchTarget,
    double? buttonHeight,
    double? logoSm,
    double? logoLg,
    double? recordButton,
    double? maxContentWidth,
    double? borderWidth,
    double? notesMaxHeight,
  }) => AppSizes(
    iconSm: iconSm ?? this.iconSm,
    iconMd: iconMd ?? this.iconMd,
    iconLg: iconLg ?? this.iconLg,
    iconXl: iconXl ?? this.iconXl,
    touchTarget: touchTarget ?? this.touchTarget,
    buttonHeight: buttonHeight ?? this.buttonHeight,
    logoSm: logoSm ?? this.logoSm,
    logoLg: logoLg ?? this.logoLg,
    recordButton: recordButton ?? this.recordButton,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    borderWidth: borderWidth ?? this.borderWidth,
    notesMaxHeight: notesMaxHeight ?? this.notesMaxHeight,
  );

  @override
  AppSizes lerp(covariant AppSizes? other, double t) {
    if (other == null) return this;
    return AppSizes(
      iconSm: _l(iconSm, other.iconSm, t),
      iconMd: _l(iconMd, other.iconMd, t),
      iconLg: _l(iconLg, other.iconLg, t),
      iconXl: _l(iconXl, other.iconXl, t),
      touchTarget: _l(touchTarget, other.touchTarget, t),
      buttonHeight: _l(buttonHeight, other.buttonHeight, t),
      logoSm: _l(logoSm, other.logoSm, t),
      logoLg: _l(logoLg, other.logoLg, t),
      recordButton: _l(recordButton, other.recordButton, t),
      maxContentWidth: _l(maxContentWidth, other.maxContentWidth, t),
      borderWidth: _l(borderWidth, other.borderWidth, t),
      notesMaxHeight: _l(notesMaxHeight, other.notesMaxHeight, t),
    );
  }
}

/// Shadows mirroring tailwind `shadow-card` / `shadow-elevated`. Access: `context.shadows`.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({required this.card, required this.elevated});

  final List<BoxShadow> card;
  final List<BoxShadow> elevated;

  static const AppShadows light = AppShadows(
    card: [
      BoxShadow(color: Color(0x0A101828), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0F101828), offset: Offset(0, 1), blurRadius: 3),
    ],
    elevated: [BoxShadow(color: Color(0x14101828), offset: Offset(0, 8), blurRadius: 24)],
  );

  static const AppShadows dark = AppShadows(
    card: [BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 3)],
    elevated: [BoxShadow(color: Color(0x52000000), offset: Offset(0, 8), blurRadius: 24)],
  );

  @override
  AppShadows copyWith({List<BoxShadow>? card, List<BoxShadow>? elevated}) =>
      AppShadows(card: card ?? this.card, elevated: elevated ?? this.elevated);

  @override
  AppShadows lerp(covariant AppShadows? other, double t) {
    if (other == null) return this;
    return AppShadows(
      card: BoxShadow.lerpList(card, other.card, t)!,
      elevated: BoxShadow.lerpList(elevated, other.elevated, t)!,
    );
  }
}
