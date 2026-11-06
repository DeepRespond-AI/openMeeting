import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:mocktail/mocktail.dart';

class AvatarClient extends Mock implements DRClient {}

class AvatarUsers extends Mock implements UsersModule {}

class AvatarFiles extends Mock implements FilesModule {}

Uint8List get avatarPng => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jG3cAAAAASUVORK5CYII=',
);
DRFile get avatarInput => DRFile.fromBytes(avatarPng, name: 'avatar.png');

/// Deterministic SDK boundary shared by isolated smoke tests and page acceptance.
/// The production profile subscription and upload/save controller stay intact.
class AvatarFixture {
  AvatarFixture() {
    when(() => client.users).thenReturn(users);
    when(() => client.files).thenReturn(files);
    when(() => client.on<MeChanged>()).thenAnswer((_) => meEvents.stream);
    when(() => client.on<UsersChanged>()).thenAnswer((_) => userEvents.stream);
    when(users.me).thenAnswer((_) => me);
    when(() => users.get(any())).thenAnswer((call) => profiles[call.positionalArguments.single]);
    when(
      () => files.upload(
        any(),
        purpose: any(named: 'purpose'),
        kind: any(named: 'kind'),
        cancel: any(named: 'cancel'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((call) {
      uploads++;
      lastPurpose = call.namedArguments[#purpose] as String;
      lastKind = call.namedArguments[#kind] as String?;
      lastCancel = call.namedArguments[#cancel] as DRCancelToken?;
      final progress = call.namedArguments[#onProgress] as void Function(int, int)?;
      progress?.call(1, 2);
      final result =
          uploadGate?.future ??
          (uploadError
              ? Future<FileInfo>.error(StateError('fixture upload failed'))
              : Future.value(
                  FileInfo({'url': avatarUrl, 'purpose': 'user_avatar', 'kind': 'image'}),
                ));
      return UploadTask(result, const Stream.empty(), () => lastCancel?.cancel());
    });
    when(() => users.updateMe(avatarUrl: any(named: 'avatarUrl'))).thenAnswer((call) async {
      saves++;
      if (saveGate != null) await saveGate!.future;
      if (saveError) throw StateError('fixture save failed');
      me = SelfProfile({
        ...me.raw,
        'avatar_url': call.namedArguments[#avatarUrl],
        'version': me.version + 1,
      });
      meEvents.add(MeChanged(me));
      return me;
    });
  }
  static void register() {
    registerFallbackValue(avatarInput);
    registerFallbackValue(DRCancelToken());
  }

  final client = AvatarClient();
  final users = AvatarUsers();
  final files = AvatarFiles();
  final meEvents = StreamController<MeChanged>.broadcast(sync: true);
  final userEvents = StreamController<UsersChanged>.broadcast(sync: true);
  SelfProfile me = const SelfProfile({
    'username': 'self-id',
    'nickname': '林小明',
    'avatar_url': '',
    'version': 1,
  });
  final profiles = <String, UserProfile>{};
  bool uploadError = false, saveError = false;
  String avatarUrl = 'https://example.test/avatar.png';
  int uploads = 0, saves = 0;
  String? lastPurpose, lastKind;
  DRCancelToken? lastCancel;
  Completer<FileInfo>? uploadGate;
  Completer<void>? saveGate;
  void profile(String username, {required String name, String avatar = ''}) {
    profiles[username] = UserProfile({
      'username': username,
      'nickname': name,
      'avatar_url': avatar,
    });
    userEvents.add(UsersChanged([username]));
  }

  Future<void> dispose() async {
    await meEvents.close();
    await userEvents.close();
  }
}
