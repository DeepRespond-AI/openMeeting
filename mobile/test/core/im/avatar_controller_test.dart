import 'dart:async';
import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart' hide AuthState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/avatar_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/user_profile.dart';

import '../../helpers/avatar_fixture.dart';
import '../../helpers/test_config.dart';

class AvatarTestSession extends SessionController {
  @override
  Future<AuthState> build() async => const AuthState.signedIn(User(id: 'self-id', name: '林小明'));
  void switchAccount() =>
      state = const AsyncData(AuthState.signedIn(User(id: 'other-id', name: 'Other')));
}

void main() {
  setUpAll(AvatarFixture.register);
  test('profile labels prefer nickname and never fall back to a technical ID', () {
    const profile = UserProfile({'username': 'd3f721c1-uuid', 'nickname': '  张同学  '});
    expect(identityName(profile, '会议姓名', '用户'), '张同学');
    expect(identityName(const UserProfile({'username': 'uuid'}), '会议姓名', '用户'), '会议姓名');
    expect(identityName(null, '', '用户'), '用户');
    expect(
      identityName(const UserProfile({'username': 'uuid', 'nickname': 'uuid'}), '会议姓名', '用户'),
      '会议姓名',
    );
  });
  test('file signatures accept image types and reject renamed arbitrary data', () {
    expect(avatarMime(avatarPng), 'image/png');
    expect(avatarMime(Uint8List.fromList([255, 216, 255, 1])), 'image/jpeg');
    expect(
      avatarMime(Uint8List.fromList([82, 73, 70, 70, 0, 0, 0, 0, 87, 69, 66, 80])),
      'image/webp',
    );
    expect(avatarMime(Uint8List.fromList('fake.png'.codeUnits)), isNull);
  });
  for (final mode in ['success', 'cancel', 'type', 'size', 'upload', 'save', 'account-switch']) {
    test('avatar deterministic $mode', () async {
      final f = AvatarFixture();
      addTearDown(f.dispose);
      final c = await createTestContainer(
        overrides: [
          sessionControllerProvider.overrideWith(AvatarTestSession.new),
          imClientProvider.overrideWith((_) async => f.client),
          avatarPickerProvider.overrideWith(
            (_) =>
                () async => switch (mode) {
                  'cancel' => null,
                  'type' => DRFile.fromBytes(Uint8List.fromList([1, 2, 3]), name: 'fake.png'),
                  'size' => DRFile.fromBytes(Uint8List(5242881), name: 'large.png'),
                  _ => avatarInput,
                },
          ),
        ],
      );
      await c.read(sessionControllerProvider.future);
      final sub = c.listen(avatarControllerProvider, (_, _) {});
      addTearDown(sub.close);
      f.uploadError = mode == 'upload';
      f.saveError = mode == 'save';
      if (mode == 'account-switch') f.uploadGate = Completer<FileInfo>();
      final ctl = c.read(avatarControllerProvider.notifier);
      final operation = ctl.pickAndSave();
      if (mode == 'account-switch') {
        await Future<void>.delayed(Duration.zero);
        expect(c.read(avatarControllerProvider).phase, AvatarPhase.uploading);
        (c.read(sessionControllerProvider.notifier) as AvatarTestSession).switchAccount();
        c.read(avatarControllerProvider);
        f.uploadGate!.complete(const FileInfo({'url': 'https://example.test/old.png'}));
      }
      final passed = await operation;
      final status = c.read(avatarControllerProvider);
      if (mode == 'success') {
        expect(passed, true);
        expect(status.phase, AvatarPhase.saved);
        expect(f.lastPurpose, UploadPurpose.userAvatar);
        expect(f.lastKind, FileKind.image);
        expect(f.me.avatarUrl, f.avatarUrl);
      } else {
        expect(passed, false);
        expect(f.me.avatarUrl, '');
        if (['type', 'size', 'cancel'].contains(mode)) expect(f.uploads, 0);
        if (mode == 'upload' || mode == 'account-switch') expect(f.saves, 0);
        if (mode == 'account-switch') expect(f.lastCancel?.isCancelled, true);
        if (['type', 'size', 'upload', 'save'].contains(mode)) {
          expect(status.failure?.name, mode);
          f.uploadError = f.saveError = false;
          if (mode == 'upload' || mode == 'save') {
            expect(await ctl.pickAndSave(), true);
            expect(f.me.avatarUrl, f.avatarUrl);
          }
        }
      }
    });
  }
  test('SDK cache hydration and self/remote updates rebuild profile subscribers', () async {
    final f = AvatarFixture();
    addTearDown(f.dispose);
    final c = await createTestContainer(
      overrides: [imClientProvider.overrideWith((_) async => f.client)],
    );
    final remote = c.listen(imUserProfileProvider('remote-id'), (_, _) {});
    final own = c.listen(imUserProfileProvider('self-id'), (_, _) {});
    addTearDown(remote.close);
    addTearDown(own.close);
    expect(await c.read(imUserProfileProvider('remote-id').future), isNull);
    expect((await c.read(imUserProfileProvider('self-id').future))?.nickname, '林小明');
    f.profile('remote-id', name: '远端同学', avatar: 'https://example.test/new.png');
    f.me = const SelfProfile({
      'username': 'self-id',
      'nickname': '新姓名',
      'avatar_url': 'https://example.test/self.png',
    });
    f.meEvents.add(MeChanged(f.me));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(imUserProfileProvider('remote-id')).value?.nickname, '远端同学');
    expect(
      c.read(imUserProfileProvider('self-id')).value?.avatarUrl,
      'https://example.test/self.png',
    );
    remote.close();
    own.close();
    await c.pump();
    expect(f.userEvents.hasListener, false);
    expect(f.meEvents.hasListener, false);
  });
}
