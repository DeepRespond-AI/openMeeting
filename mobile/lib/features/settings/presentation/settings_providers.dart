import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/data/client_info_source.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/heartbeat/recording_status.dart';
import '../domain/phone_mask.dart';

part 'settings_providers.g.dart';

/// App version shown in "About" (same value that is reported to the server).
@riverpod
Future<String> settingsAppVersion(Ref ref) async =>
    (await ref.watch(clientInfoProvider.future)).appVersion;

/// The signed-in user's phone, masked per `AppConfig.auth.phoneMask*`; null when unknown.
@riverpod
String? maskedPhone(Ref ref) {
  final phone = ref.watch(currentUserProvider.select((u) => u?.phone));
  if (phone == null || phone.isEmpty) return null;
  final auth = ref.watch(appConfigProvider).auth;
  return maskPhone(
    phone,
    visiblePrefix: auth.phoneMaskPrefixLength,
    visibleSuffix: auth.phoneMaskSuffixLength,
  );
}

/// True while recording: logout and server changes are disabled.
@riverpod
bool settingsLocked(Ref ref) =>
    ref.watch(recordingStatusControllerProvider.select((s) => s.recording));
