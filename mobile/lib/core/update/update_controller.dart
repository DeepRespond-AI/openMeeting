import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/data/client_info_source.dart';
import '../config/app_config_provider.dart';
import '../config/settings_store.dart';
import '../data/background_work.dart';
import 'data/update_installer.dart';
import 'data/update_repository.dart';
import 'update_models.dart';

part 'update_controller.freezed.dart';
part 'update_controller.g.dart';

/// Distribution channel of this build (`APP_CHANNEL`); a provider so tests can override it.
@Riverpod(keepAlive: true)
String updateChannel(Ref ref) => appChannel;

@Riverpod(keepAlive: true)
DateTime Function() updateClock(Ref ref) => DateTime.now;

enum UpdatePhase { idle, checking, downloading, installing }

/// Why the last install attempt stopped (localized by the UI).
enum UpdateFailure { download, checksum, permission, install, store, syncing }

/// Result of a manual check (Settings → About).
enum UpdateCheckOutcome { upToDate, available, failed }

@freezed
abstract class UpdateState with _$UpdateState {
  const factory UpdateState({
    /// The release offered by the server; null = up to date (or not checked yet).
    UpdateOffer? offer,
    @Default(UpdatePhase.idle) UpdatePhase phase,

    /// Download progress 0..1; null while the size is unknown.
    double? progress,
    UpdateFailure? failure,
  }) = _UpdateState;

  const UpdateState._();

  /// A forced update is pending: the app is blocked until it is installed.
  bool get required => offer?.force ?? false;

  bool get busy => phase == UpdatePhase.downloading || phase == UpdatePhase.installing;
}

/// SharedPreferences keys of the optional-update prompt cooldown.
abstract final class _PromptKeys {
  static const String version = 'update.promptedVersion';
  static const String at = 'update.promptedAtMs';
}

/// App upgrades (server/API.md §1.8): checks on start-up, on resume and periodically
/// (throttled by `AppConfig.update.checkInterval`), and installs the offered release —
/// download + SHA-256 check + system installer for the Android `direct` build, the store page
/// otherwise. A forced offer blocks the app (route guard → force-update page).
@Riverpod(keepAlive: true)
class UpdateController extends _$UpdateController {
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  DateTime? _lastCheck;

  @override
  UpdateState build() {
    final interval = ref.read(appConfigProvider).update.checkInterval;
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(check()));
    _timer = Timer.periodic(interval, (_) => unawaited(check()));
    ref.onDispose(() {
      _lifecycle?.dispose();
      _timer?.cancel();
    });
    scheduleMicrotask(() => unawaited(check()));
    return const UpdateState();
  }

  /// Asks the server for a newer release. Background checks are skipped within the check
  /// interval; [manual] checks always run. Returns null when skipped.
  Future<UpdateCheckOutcome?> check({bool manual = false}) async {
    if (state.phase != UpdatePhase.idle) return null;
    final now = ref.read(updateClockProvider)();
    final interval = ref.read(appConfigProvider).update.checkInterval;
    final last = _lastCheck;
    if (!manual && last != null && now.difference(last) < interval) return null;
    _lastCheck = now;
    state = state.copyWith(phase: UpdatePhase.checking);
    try {
      final client = await ref.read(clientInfoProvider.future);
      final result = await ref
          .read(updateRepositoryProvider)
          .check(
            platform: client.os,
            version: client.appVersion,
            channel: ref.read(updateChannelProvider),
            clientId: client.clientId,
          );
      if (!ref.mounted) return null;
      state = state.copyWith(offer: result.update, phase: UpdatePhase.idle, failure: null);
      return result.update == null ? UpdateCheckOutcome.upToDate : UpdateCheckOutcome.available;
    } on Object catch (e) {
      debugPrint('Update check failed: $e');
      if (ref.mounted) state = state.copyWith(phase: UpdatePhase.idle);
      return UpdateCheckOutcome.failed;
    }
  }

  /// Whether the optional-update dialog should be shown for [offer] (cooldown per version).
  bool shouldPrompt(UpdateOffer offer) {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getString(_PromptKeys.version) != offer.fullVersion) return true;
    final at = prefs.getInt(_PromptKeys.at);
    if (at == null) return true;
    final elapsed = ref
        .read(updateClockProvider)()
        .difference(DateTime.fromMillisecondsSinceEpoch(at));
    return elapsed >= ref.read(appConfigProvider).update.promptCooldown;
  }

  Future<void> markPrompted(UpdateOffer offer) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_PromptKeys.version, offer.fullVersion);
    await prefs.setInt(_PromptKeys.at, ref.read(updateClockProvider)().millisecondsSinceEpoch);
  }

  /// Installs the offered release: store page, or download → verify → system installer.
  Future<void> install() async {
    final offer = state.offer;
    if (offer == null || state.phase != UpdatePhase.idle) return;
    final installer = ref.read(updateInstallerProvider);
    state = state.copyWith(failure: null);

    final storeUrl = offer.storeUrl;
    if (storeUrl != null) {
      final opened = await _guard(() => installer.openStore(storeUrl), fallback: false);
      if (!opened && ref.mounted) state = state.copyWith(failure: UpdateFailure.store);
      return;
    }
    final url = offer.downloadUrl;
    if (url == null) return;
    // Installing replaces the app: wait until stopped recordings / imports have synced.
    if (ref.read(meetingSyncProvider).isNotEmpty) {
      state = state.copyWith(failure: UpdateFailure.syncing);
      return;
    }
    if (!await _guard(installer.canInstallPackages, fallback: false)) {
      if (!ref.mounted) return;
      state = state.copyWith(failure: UpdateFailure.permission);
      await _guard(installer.openInstallSettings, fallback: null);
      return;
    }

    state = state.copyWith(phase: UpdatePhase.downloading, progress: 0);
    final File file;
    try {
      final dir = await installer.downloadDir();
      file = File('${dir.path}/${ref.read(appConfigProvider).update.apkFileName}');
      if (file.existsSync()) await file.delete();
      await ref
          .read(updateRepositoryProvider)
          .download(
            url,
            file.path,
            onProgress: (received, total) {
              if (!ref.mounted || state.phase != UpdatePhase.downloading) return;
              state = state.copyWith(progress: total > 0 ? received / total : null);
            },
          );
    } on Object catch (e) {
      debugPrint('Update download failed: $e');
      if (ref.mounted) _fail(UpdateFailure.download);
      return;
    }

    final expected = offer.sha256;
    if (expected != null && !await _matchesSha256(file, expected)) {
      await _guard(file.delete, fallback: null);
      if (ref.mounted) _fail(UpdateFailure.checksum);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(phase: UpdatePhase.installing, progress: 1);
    try {
      await installer.installApk(file.path);
      // The system installer takes over; installing replaces (and restarts) the app.
      if (ref.mounted) state = state.copyWith(phase: UpdatePhase.idle);
    } on Object catch (e) {
      debugPrint('Starting the installer failed: $e');
      if (ref.mounted) _fail(UpdateFailure.install);
    }
  }

  void _fail(UpdateFailure failure) =>
      state = state.copyWith(phase: UpdatePhase.idle, progress: null, failure: failure);

  static Future<bool> _matchesSha256(File file, String expected) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expected.toLowerCase();
  }

  static Future<T> _guard<T>(Future<T> Function() body, {required T fallback}) async {
    try {
      return await body();
    } on Object catch (e) {
      debugPrint('Update step failed: $e');
      return fallback;
    }
  }
}
