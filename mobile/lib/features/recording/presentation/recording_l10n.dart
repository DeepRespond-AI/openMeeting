import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/settings_controller.dart';
import '../../../core/l10n/l10n.dart';

part 'recording_l10n.g.dart';

/// Localizations for text produced outside the widget tree (meeting title, notification),
/// resolved like `MaterialApp` does: the UI language setting, else the device locale.
@Riverpod(keepAlive: true)
AppLocalizations recordingL10n(Ref ref) {
  final mode = ref.watch(localeModeProvider);
  return lookupAppLocalizations(resolveAppLocale(mode, PlatformDispatcher.instance.locales));
}
