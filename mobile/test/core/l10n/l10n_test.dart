import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/l10n/l10n.dart';

Set<String> _keys(String file) =>
    (jsonDecode(File('lib/core/l10n/$file').readAsStringSync()) as Map<String, dynamic>).keys
        .where((k) => !k.startsWith('@'))
        .toSet();

void main() {
  test('zh and en ARB files define the same keys', () {
    expect(_keys('app_en.arb'), _keys('app_zh.arb'));
  });

  test('app name per locale', () {
    expect(lookupAppLocalizations(const Locale('zh')).appName, '深应会议');
    expect(lookupAppLocalizations(const Locale('en')).appName, 'DR Meeting');
  });

  test('locale resolution', () {
    const zhCn = Locale('zh', 'CN');
    const enUs = Locale('en', 'US');
    const ja = Locale('ja');
    expect(resolveAppLocale(LocaleMode.system, [zhCn, enUs]), const Locale('zh'));
    expect(resolveAppLocale(LocaleMode.system, [enUs, zhCn]), const Locale('en'));
    expect(resolveAppLocale(LocaleMode.system, [ja]), const Locale('en'));
    expect(resolveAppLocale(LocaleMode.system, null), const Locale('en'));
    expect(resolveAppLocale(LocaleMode.zh, [enUs]), const Locale('zh'));
    expect(resolveAppLocale(LocaleMode.en, [zhCn]), const Locale('en'));
    expect(localeForMode(LocaleMode.system), isNull);
  });
}
