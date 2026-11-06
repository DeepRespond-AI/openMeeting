import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/screen_controller.dart';

class _Room extends RoomController {
  static const host = LiveParticipant(id: 'host', name: 'Host', isHost: true, isSelf: true);
  @override
  LiveRoomState build() => const RoomActive(
    room: LiveRoom(id: 'room', code: '123456', title: 'Room', hostId: 'host'),
    self: host,
  );
  void replaceSelf(LiveParticipant self) => state = (state as RoomActive).copyWith(self: self);
}

class _Screen extends RoomScreen {
  @override
  ScreenState build() => const ScreenState();
}

void main() {
  testWidgets('only guest has a hand action, including when roles change', (tester) async {
    final container = ProviderContainer(
      overrides: [
        roomControllerProvider.overrideWith(_Room.new),
        roomScreenProvider.overrideWith(_Screen.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RoomMorePanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.back_hand_outlined), findsNothing);
    final controller = container.read(roomControllerProvider.notifier) as _Room;
    controller.replaceSelf(_Room.host.copyWith(isHost: false));
    await tester.pump();
    expect(find.byIcon(Icons.back_hand_outlined), findsOneWidget);
    controller.replaceSelf(_Room.host.copyWith(handRaised: true));
    await tester.pump();
    expect(find.byIcon(Icons.back_hand_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
