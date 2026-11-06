import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/features/messaging/presentation/messaging_controller.dart';

class LateClient implements DRClient {
  int accessCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    accessCount++;
    throw StateError('A disposed provider must not create an SDK list.');
  }
}

void main() {
  for (final name in ['conversations', 'friends', 'groups', 'members']) {
    test('$name: disposing during IM initialization does not access the stale Ref', () async {
      final pending = Completer<DRClient>();
      final client = LateClient();
      final container = ProviderContainer(
        overrides: [imClientProvider.overrideWith((ref) => pending.future)],
      );
      addTearDown(container.dispose);
      final subscription = switch (name) {
        'conversations' => container.listen(imConversationsProvider, (_, _) {}),
        'friends' => container.listen(imFriendsProvider, (_, _) {}),
        'groups' => container.listen(imGroupsProvider, (_, _) {}),
        _ => container.listen(imMembersProvider('test-group'), (_, _) {}),
      };
      await Future<void>.delayed(Duration.zero);
      subscription.close();
      await container.pump();
      pending.complete(client);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await container.pump();
      expect(client.accessCount, 0);
    });
  }
}
