import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/screen_capture.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/screen_controller.dart';

import '../../helpers/core_media_fixture.dart';
import '../../helpers/test_config.dart';

void main() {
  for (final mode in [
    'success',
    'denied',
    'admission',
    'publish',
    'late-capture',
    'late-claim',
    'replaced',
    'ended',
    'native-ended',
  ]) {
    test('screen fixture $mode stops pixels and reconciles its own claim', () async {
      final f = CoreMediaFixture();
      final c = await createTestContainer(
        overrides: [
          roomControllerProvider.overrideWith(CoreRoomController.new),
          liveRepositoryProvider.overrideWithValue(f.repo),
          captureScreenProvider.overrideWithValue(f.acquire),
        ],
      );
      c.read(roomChannelProvider.notifier).set(f.channel);
      final screen = c.read(roomScreenProvider.notifier);
      if (mode == 'denied') f.denyCapture = true;
      if (mode == 'admission') f.failClaim = true;
      if (mode == 'publish') f.capture.failPublish = true;
      if (mode == 'late-capture') f.captureGate = Completer<ScreenCapture>();
      if (mode == 'late-claim') f.claimGate = Completer<void>();
      final start = screen.start('Share', 'Consent required');
      await Future<void>.delayed(Duration.zero);
      if (mode == 'late-capture' || mode == 'late-claim') {
        await screen.stop();
        f.captureGate?.complete(f.capture);
        f.claimGate?.complete();
      }
      await start;
      if (mode == 'denied') {
        expect(c.read(roomScreenProvider).error, ScreenFailure.denied);
        expect(f.starts, 0);
        expect(f.capture.published, 0);
      } else if (mode == 'admission' || mode == 'publish') {
        expect(c.read(roomScreenProvider).error, ScreenFailure.start);
        expect(f.capture.closed, greaterThan(0));
        if (mode == 'publish') expect(f.stops, [CoreMediaFixture.claim]);
      } else if (mode.startsWith('late-')) {
        expect(c.read(roomScreenProvider).phase, ScreenPhase.idle);
        expect(f.capture.published, 0);
        expect(f.capture.closed, greaterThan(0));
        if (mode == 'late-claim') expect(f.stops, [CoreMediaFixture.claim]);
      } else {
        expect(c.read(roomScreenProvider).phase, ScreenPhase.sharing);
        expect(f.capture.lastClaim, CoreMediaFixture.claim);
        final roomController = c.read(roomControllerProvider.notifier) as CoreRoomController;
        if (mode == 'replaced') {
          roomController.applyRoom(
            coreRoom.copyWith(
              participants: [
                coreSelf,
                corePeer.copyWith(screenSharing: true, screenShareId: 'replacement'),
              ],
            ),
          );
        } else if (mode == 'ended') {
          roomController.replace(const RoomEnded());
        } else if (mode == 'native-ended') {
          f.capture.onEnded!();
        } else {
          await screen.start('duplicate', 'duplicate');
          expect(f.starts, 1);
          await screen.stop();
        }
        await Future<void>.delayed(Duration.zero);
        expect(f.capture.closed, greaterThan(0));
        expect(f.stops, [CoreMediaFixture.claim]);
        expect(c.read(roomScreenProvider).phase, ScreenPhase.idle);
        if (mode == 'replaced') expect(c.read(roomScreenProvider).error, ScreenFailure.replaced);
      }
    });
  }
}
