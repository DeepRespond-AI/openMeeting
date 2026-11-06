import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'im_gateway.dart';

part 'user_profile.g.dart';

/// Hydrate SDK-owned profiles and stay subscribed to both local and remote
/// updates. Subscribe before reading the initial snapshot to avoid lost updates.
@riverpod
Stream<UserProfile?> imUserProfile(Ref ref, String username) async* {
  if (username.trim().isEmpty) {
    yield null;
    return;
  }
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) return;
  UserProfile? current() {
    final me = client.users.me();
    if (me?.username.toLowerCase() == username.toLowerCase()) return UserProfile(me!.raw);
    return client.users.get(username);
  }

  yield* Stream<UserProfile?>.multi((sink) {
    final me = client.on<MeChanged>().listen((_) => sink.add(current()));
    final users = client.on<UsersChanged>().listen((event) {
      if (event.usernames.any((name) => name.toLowerCase() == username.toLowerCase())) {
        sink.add(current());
      }
    });
    ref.onDispose(() {
      unawaited(me.cancel());
      unawaited(users.cancel());
    });
    sink.onCancel = () async {
      await me.cancel();
      await users.cancel();
    };
    sink.add(current());
  });
}

/// A missing public nickname must never turn a business UUID into a UI label.
String identityName(UserProfile? profile, String? fallback, String unknown) {
  final nickname = profile?.nickname.trim() ?? '';
  if (nickname.isNotEmpty && nickname.toLowerCase() != profile?.username.toLowerCase()) {
    return nickname;
  }
  final name = fallback?.trim() ?? '';
  return name.isNotEmpty ? name : unknown;
}
