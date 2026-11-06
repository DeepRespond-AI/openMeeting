/// Localization entry point. Import this (not `gen/`) from feature code.
///
/// Add a string: put the key in `app_zh.arb` (template, with `@key` metadata for
/// placeholders) AND `app_en.arb`, then run `flutter gen-l10n` (also runs on `flutter pub get`
/// / build). Use it as `context.l10n.myKey` (see `core/theme/context_extensions.dart`).
library;

import 'dart:ui';

import '../config/app_enums.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Locales the app ships, Chinese first (template locale).
const List<Locale> appSupportedLocales = [Locale('zh'), Locale('en')];

/// The explicit locale for [mode], or `null` for [LocaleMode.system] (MaterialApp then
/// resolves through [resolveSystemLocale]).
Locale? localeForMode(LocaleMode mode) => switch (mode) {
  LocaleMode.system => null,
  LocaleMode.zh => const Locale('zh'),
  LocaleMode.en => const Locale('en'),
};

/// System locale rule: Chinese if the device's preferred language is Chinese, else English.
Locale resolveSystemLocale(List<Locale>? deviceLocales) {
  final preferred = (deviceLocales == null || deviceLocales.isEmpty) ? null : deviceLocales.first;
  return preferred?.languageCode == 'zh' ? const Locale('zh') : const Locale('en');
}

/// Resolves the effective locale for [mode] given the device locales (pure; used in tests).
Locale resolveAppLocale(LocaleMode mode, List<Locale>? deviceLocales) =>
    localeForMode(mode) ?? resolveSystemLocale(deviceLocales);

/// Delegates for MaterialApp.
const localizationsDelegates = AppLocalizations.localizationsDelegates;
