import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/client_info_source.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/data/background_work.dart';
import 'package:meeting/core/update/data/update_installer.dart';
import 'package:meeting/core/update/data/update_repository.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/core/update/update_models.dart';

import '../../helpers/test_config.dart';

const _apk = 'apk-bytes';

UpdateOffer _offer({bool force = false, String? storeUrl, String? sha}) => UpdateOffer(
  id: 'r1',
  version: '1.0.1',
  build: 2,
  fullVersion: '1.0.1+2',
  notes: '修复问题',
  force: force,
  sha256: storeUrl == null ? (sha ?? sha256.convert(utf8.encode(_apk)).toString()) : null,
  downloadUrl: storeUrl == null ? 'https://srv/api/v1/updates/download/a1' : null,
  storeUrl: storeUrl,
);

class FakeUpdateRepository implements UpdateRepository {
  UpdateOffer? offer;
  Object? checkError;
  Object? downloadError;
  final List<Map<String, String>> checks = [];

  @override
  Future<UpdateCheckResult> check({
    required String platform,
    required String version,
    required String channel,
    required String clientId,
  }) async {
    checks.add({
      'platform': platform,
      'version': version,
      'channel': channel,
      'clientId': clientId,
    });
    if (checkError case final e?) throw e;
    return UpdateCheckResult(update: offer);
  }

  @override
  Future<void> download(String url, String path, {DownloadProgress? onProgress}) async {
    if (downloadError case final e?) throw e;
    onProgress?.call(4, 9);
    await File(path).writeAsString(_apk);
    onProgress?.call(9, 9);
  }
}

class FakeInstaller implements UpdateInstaller {
  FakeInstaller(this.dir);

  final Directory dir;
  bool allowed = true;
  bool storeOpens = true;
  final List<String> calls = [];

  @override
  Future<bool> canInstallPackages() async => allowed;

  @override
  Future<void> openInstallSettings() async => calls.add('settings');

  @override
  Future<void> installApk(String path) async =>
      calls.add('install:${File(path).readAsStringSync()}');

  @override
  Future<bool> openStore(String url) async {
    calls.add('store:$url');
    return storeOpens;
  }

  @override
  Future<Directory> downloadDir() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUpdateRepository repo;
  late FakeInstaller installer;
  late DateTime now;

  Future<ProviderContainer> container({
    String channel = 'direct',
    Map<String, Object> prefs = const {},
  }) async {
    final c = await createTestContainer(
      prefs: prefs,
      overrides: [
        updateRepositoryProvider.overrideWithValue(repo),
        updateInstallerProvider.overrideWithValue(installer),
        updateChannelProvider.overrideWithValue(channel),
        updateClockProvider.overrideWithValue(() => now),
        clientInfoProvider.overrideWith(
          (ref) async => const ClientInfo(
            clientId: 'cid',
            hostname: 'Pixel',
            os: 'android',
            appVersion: '1.0.0+1',
          ),
        ),
      ],
    );
    final sub = c.listen(updateControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero); // the start-up check
    return c;
  }

  setUp(() {
    repo = FakeUpdateRepository();
    installer = FakeInstaller(Directory.systemTemp.createTempSync('update-test'));
    now = DateTime(2026, 10, 8, 9);
  });

  test('checks on start-up with this build’s version, channel and client id', () async {
    repo.offer = _offer();
    final c = await container(channel: 'huawei');
    expect(repo.checks.single, {
      'platform': 'android',
      'version': '1.0.0+1',
      'channel': 'huawei',
      'clientId': 'cid',
    });
    expect(c.read(updateControllerProvider).offer?.fullVersion, '1.0.1+2');
    expect(c.read(updateControllerProvider).required, isFalse);
  });

  test('background checks are throttled; manual checks always run', () async {
    final c = await container();
    final updates = c.read(updateControllerProvider.notifier);
    expect(await updates.check(), isNull, reason: 'within the interval');
    expect(await updates.check(manual: true), UpdateCheckOutcome.upToDate);
    now = now.add(c.read(appConfigProvider).update.checkInterval);
    repo.offer = _offer(force: true);
    expect(await updates.check(), UpdateCheckOutcome.available);
    expect(c.read(updateControllerProvider).required, isTrue);
    repo.checkError = const ApiException(kind: ApiErrorKind.network);
    expect(await updates.check(manual: true), UpdateCheckOutcome.failed);
    expect(
      c.read(updateControllerProvider).offer,
      isNotNull,
      reason: 'a failed check keeps the offer',
    );
    expect(repo.checks, hasLength(4));
  });

  test('prompt cooldown per version', () async {
    repo.offer = _offer();
    final c = await container();
    final updates = c.read(updateControllerProvider.notifier);
    final offer = c.read(updateControllerProvider).offer!;
    expect(updates.shouldPrompt(offer), isTrue);
    await updates.markPrompted(offer);
    expect(updates.shouldPrompt(offer), isFalse);
    expect(updates.shouldPrompt(offer.copyWith(fullVersion: '1.0.2+3')), isTrue);
    now = now.add(c.read(appConfigProvider).update.promptCooldown);
    expect(updates.shouldPrompt(offer), isTrue);
  });

  test('direct build: download, verify, hand to the installer', () async {
    repo.offer = _offer();
    final c = await container();
    final progress = <double?>[];
    c.listen(updateControllerProvider.select((s) => s.progress), (_, p) => progress.add(p));
    await c.read(updateControllerProvider.notifier).install();
    expect(installer.calls, ['install:$_apk']);
    expect(progress, containsAllInOrder([closeTo(4 / 9, 1e-9), 1.0]));
    expect(c.read(updateControllerProvider).phase, UpdatePhase.idle);
    expect(c.read(updateControllerProvider).failure, isNull);
  });

  test('install permission missing → settings, nothing downloaded', () async {
    repo.offer = _offer();
    installer.allowed = false;
    final c = await container();
    await c.read(updateControllerProvider.notifier).install();
    expect(installer.calls, ['settings']);
    expect(c.read(updateControllerProvider).failure, UpdateFailure.permission);
  });

  test('checksum mismatch and download errors are reported', () async {
    repo.offer = _offer(sha: 'deadbeef');
    final c = await container();
    final updates = c.read(updateControllerProvider.notifier);
    await updates.install();
    expect(c.read(updateControllerProvider).failure, UpdateFailure.checksum);
    expect(installer.calls, isEmpty);
    expect(installer.dir.listSync(), isEmpty, reason: 'the bad package is deleted');

    repo.downloadError = const ApiException(kind: ApiErrorKind.network);
    await updates.install();
    expect(c.read(updateControllerProvider).failure, UpdateFailure.download);
    expect(c.read(updateControllerProvider).phase, UpdatePhase.idle);
  });

  test('waits while meetings sync in the background', () async {
    repo.offer = _offer();
    final c = await container();
    c.read(meetingSyncProvider.notifier).begin('m1');
    await c.read(updateControllerProvider.notifier).install();
    expect(c.read(updateControllerProvider).failure, UpdateFailure.syncing);
    expect(installer.calls, isEmpty);
  });

  test('store channel / iOS open the store page', () async {
    repo.offer = _offer(storeUrl: 'appmarket://details?id=cn.deeprespond.meeting');
    final c = await container(channel: 'huawei');
    await c.read(updateControllerProvider.notifier).install();
    expect(installer.calls, ['store:appmarket://details?id=cn.deeprespond.meeting']);
    installer.storeOpens = false;
    await c.read(updateControllerProvider.notifier).install();
    expect(c.read(updateControllerProvider).failure, UpdateFailure.store);
  });
}
