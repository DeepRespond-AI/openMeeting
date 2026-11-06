import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im_call/deeprespond_im_call.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/retry.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/data/meetings_changed.dart';
import '../../../core/im/channel_media.dart';
import '../../../core/im/im_gateway.dart';
import '../../../core/im/live_activity.dart';
import '../../../core/im/messaging_controller.dart';
import '../../../core/im/room_audio_recorder.dart';
import '../../../core/im/rtc_connection_failure.dart';
import '../../../core/im/rtc_session_release.dart';
import '../data/live_repository_impl.dart';
import '../domain/live_models.dart';
import '../domain/live_repository.dart';
import 'schedules_controller.dart';

part 'room_controller.g.dart';

@Riverpod(keepAlive: true)
RoomAudioSource roomAudioSource(Ref ref) => LiveKitRoomAudioSource();

/// The app keeps this provider alive for the entire admitted room lifetime,
/// including while its chat sheet is closed or the room page is minimized.
@riverpod
void roomChatLifecycle(Ref ref) {
  final id = ref.watch(roomControllerProvider.select((s) => s is RoomActive ? s.room.id : null));
  if (id == null) return;
  final session = ref.watch(roomChatSessionProvider);
  final view = session.asData?.value;
  if (view != null) ref.watch(imMessagesProvider(view.conversationKey));
}

@riverpod
Future<ConversationView> roomChatSession(Ref ref) async {
  final id = ref.watch(roomControllerProvider.select((s) => s is RoomActive ? s.room.id : null));
  if (id == null) throw const ApiException(kind: ApiErrorKind.notFound);
  final repository = ref.watch(liveRepositoryProvider);
  final policy = ref.watch(appConfigProvider).network.retry;
  final binding = await retry(() {
    if (!ref.mounted) throw const ApiException(kind: ApiErrorKind.cancelled);
    return repository.chatSession(id);
  }, policy: policy);
  if (!ref.mounted) throw const ApiException(kind: ApiErrorKind.cancelled);
  if (binding['transport'] != 'dr-im-group' || binding['groupId'] is! String) {
    throw const ApiException(kind: ApiErrorKind.unavailable);
  }
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) throw const ApiException(kind: ApiErrorKind.cancelled);
  final view = await client.conversations.refresh(binding['groupId'] as String);
  if (!ref.mounted) throw const ApiException(kind: ApiErrorKind.cancelled);
  ref.read(roomControllerProvider.notifier).setChat(view.conversationId);
  return view;
}

@Riverpod(keepAlive: true)
class RoomChannel extends _$RoomChannel {
  @override
  ChannelHandle? build() => null;
  void set(ChannelHandle? channel) => state = channel;
}

@Riverpod(keepAlive: true)
class RoomController extends _$RoomController {
  // Cancelled by cleanup(), which is also registered with ref.onDispose.
  // ignore: cancel_subscriptions
  StreamSubscription<Map<String, dynamic>>? _events;
  // Both subscriptions are cancelled by cleanup(), including ref.onDispose.
  // ignore: cancel_subscriptions
  StreamSubscription<ChannelSnapshot>? _mediaStates;
  Timer? _waiting;
  DRCancelToken? _cancel;
  ChannelHandle? _channel;
  // Released by cleanup(), which is registered with ref.onDispose.
  // ignore: cancel_subscriptions
  StreamSubscription<List<ChannelTrack>>? _audioTracks;
  RoomAudioRecorder? _recorder;
  List<ChannelTrack> _tracks = [];
  String? _chatId;
  void setChat(String? id) => _chatId = id;
  int _generation = 0;
  bool _polling = false;
  bool _operation = false;
  bool _activatingRecording = false;
  Future<void>? _mediaConnection;
  Future<void> _releaseTask = Future<void>.value();
  bool _retryingMedia = false;
  String? _activationAttempt;
  bool _wantMic = false, _wantCam = false;
  LiveRepository get _repo => ref.read(liveRepositoryProvider);
  @override
  LiveRoomState build() {
    ref.listen(sessionControllerProvider, (before, after) {
      final old = switch (before?.value) {
        AuthSignedIn(:final user) => user.id,
        _ => null,
      };
      final next = switch (after.value) {
        AuthSignedIn(:final user) => user.id,
        _ => null,
      };
      if (old != next) {
        unawaited(cleanup());
        state = const LiveRoomState.idle();
      }
    });
    ref.onDispose(() => unawaited(cleanup()));
    return const LiveRoomState.idle();
  }

  String failure(Object error) => error is ApiException
      ? (error.message ?? error.kind.name)
      : error is RtcReleaseTimeout
      ? rtcReleaseTimedOut
      : error is DRException
      ? rtcConnectionFailure(error) ?? error.message
      : error.toString();
  Future<void> cleanup() async {
    ++_generation;
    _retryingMedia = false;
    final mediaRelease = _releaseMedia();
    _waiting?.cancel();
    _waiting = null;
    final events = _events;
    _events = null;
    final recorder = _recorder;
    _recorder = null;
    _tracks = [];
    _activationAttempt = null;
    final chatId = _chatId;
    _chatId = null;
    final client = ref.mounted && chatId != null ? ref.read(imClientProvider).value : null;
    if (ref.mounted) ref.read(roomChannelProvider.notifier).set(null);
    if (ref.mounted) ref.read(liveActivityProvider.notifier).set(false);
    // Detach signaling/subscriptions immediately. Only the next media attach
    // awaits this chain; business navigation and creation stay independent.
    _releaseTask = Future.wait<void>([
      mediaRelease,
      if (events != null) events.cancel(),
      if (recorder != null) recorder.dispose(),
      if (chatId != null && client != null)
        client.conversations.remove(chatId).catchError((Object _) {}),
    ]).then((_) {});
    await _releaseTask;
  }

  Future<void> _releaseMedia() {
    final pending = _mediaConnection;
    _mediaConnection = null;
    _cancel?.cancel();
    _cancel = null;
    final channel = _channel;
    _channel = null;
    final states = _mediaStates;
    _mediaStates = null;
    final tracks = _audioTracks;
    _audioTracks = null;
    _tracks = [];
    if (ref.mounted) ref.read(roomChannelProvider.notifier).set(null);
    _releaseTask = _releaseTask.catchError((Object _) {}).then((_) async {
      await Future.wait<void>([
        if (states != null) states.cancel(),
        if (tracks != null) tracks.cancel(),
        if (channel != null) channel.leave().catchError((Object _) {}),
        if (pending != null) pending.catchError((Object _) {}),
      ]);
    });
    return _releaseTask;
  }

  Future<void> join(
    String code, {
    String? password,
    bool mic = false,
    bool cam = false,
    String? scheduledId,
    bool create = false,
    String? title,
  }) async {
    if (state is RoomJoining || state is RoomActive || state is RoomWaiting) return;
    // Match desktop: release RTC in the background. Business room creation and
    // navigation must not wait for an old SDK attach/disconnect to settle.
    unawaited(cleanup());
    final generation = _generation;
    state = const LiveRoomState.joining();
    _wantMic = mic;
    _wantCam = cam;
    try {
      final auth = ref.read(sessionControllerProvider).value;
      if (auth is! AuthSignedIn) throw const ApiException(kind: ApiErrorKind.unauthorized);
      if (create || scheduledId != null) {
        final created = await _repo.create(title: title, scheduledId: scheduledId);
        code = created.code;
      }
      if (generation != _generation) return;
      final result = await _repo.join({
        'code': code,
        'name': String.fromCharCodes(
          auth.user.name.runes.take(ref.read(appConfigProvider).live.nameMax),
        ),
        'micOn': false,
        'camOn': false,
        'pwd': ?password,
      });
      if (generation != _generation) return;
      final room = LiveRoom.fromJson(Map<String, dynamic>.from(result['room'] as Map));
      ref.invalidate(liveSchedulesProvider);
      ref.invalidate(upcomingSchedulesProvider);
      final self = LiveParticipant.fromJson(Map<String, dynamic>.from(result['self'] as Map));
      if (result['state'] == 'waiting') {
        ref.read(liveActivityProvider.notifier).set(true);
        state = LiveRoomState.waiting(room: room, self: self);
        _waiting = Timer.periodic(
          Duration(milliseconds: ref.read(appConfigProvider).live.waitingPollMs),
          (_) => unawaited(pollWaiting()),
        );
      } else {
        await activate(room, self, result['media'] as Map?);
      }
    } on Object catch (error) {
      if (generation == _generation) state = LiveRoomState.failed(failure(error));
    }
  }

  Future<void> pollWaiting() async {
    final waiting = state;
    if (waiting is! RoomWaiting || _polling) return;
    _polling = true;
    final generation = _generation;
    try {
      final room = await _repo.peek(waiting.room.code);
      if (generation != _generation) return;
      if (room.status != 'active') {
        await cleanup();
        state = const LiveRoomState.ended();
        return;
      }
      final self = room.participants.where((p) => p.id == waiting.self.id).firstOrNull;
      if (self != null) {
        _waiting?.cancel();
        _waiting = null;
        await activate(room, self, await _repo.media(room.id));
      } else if (!room.waiting.any((p) => p.participantId == waiting.self.id)) {
        _waiting?.cancel();
        state = const LiveRoomState.ended();
      } else {
        state = waiting.copyWith(room: room, error: null);
      }
    } on Object catch (error) {
      if (generation == _generation) {
        if (error is ApiException &&
            [
              ApiErrorKind.notFound,
              ApiErrorKind.forbidden,
              ApiErrorKind.unauthorized,
            ].contains(error.kind)) {
          await cleanup();
          state = const LiveRoomState.ended();
        } else {
          state = waiting.copyWith(error: failure(error));
        }
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> activate(LiveRoom room, LiveParticipant self, Map<dynamic, dynamic>? media) async {
    final generation = _generation;
    state = LiveRoomState.active(room: room, self: self);
    ref.read(liveActivityProvider.notifier).set(true);
    _events = _repo
        .events(room.id)
        .listen(
          (event) => unawaited(
            eventReceived(event, generation).catchError((Object error) {
              if (generation == _generation) report(error);
            }),
          ),
          onError: report,
        );
    unawaited(refresh());
    if (media != null) unawaited(connectMedia(Map<String, dynamic>.from(media)));
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! RoomActive) return;
    final generation = _generation;
    try {
      final snapshot = await _repo.room(current.room.id);
      if (generation != _generation || state is! RoomActive) return;
      applyRoom(snapshot);
    } on Object catch (error) {
      if (generation == _generation) report(error);
    }
  }

  List<LiveChat> merge(List<LiveChat> old, List<LiveChat> added) {
    final rows = {
      for (final item in [...old, ...added]) item.id: item,
    };
    return rows.values.toList()..sort(
      (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  void applyRoom(LiveRoom room) {
    final current = state;
    if (current is! RoomActive) return;
    if (room.status != 'active') {
      unawaited(cleanup());
      state = LiveRoomState.ended(meetingId: room.meetingId);
      return;
    }
    final self = room.participants.where((p) => p.id == current.self.id).firstOrNull;
    if (self == null) {
      unawaited(cleanup());
      state = const LiveRoomState.ended();
      return;
    }
    state = current.copyWith(room: room, self: self);
    syncRecording();
    final channel = ref.read(roomChannelProvider);
    if (!self.micOn && current.self.micOn) {
      unawaited(
        channel?.setMicrophoneEnabled(false).catchError((Object _) {}) ?? Future<void>.value(),
      );
    }
    if (!self.camOn && current.self.camOn) {
      unawaited(channel?.setCameraEnabled(false).catchError((Object _) {}) ?? Future<void>.value());
    }
  }

  Future<void> eventReceived(Map<String, dynamic> event, int generation) async {
    if (generation != _generation) return;
    final current = state;
    if (current is! RoomActive) return;
    final data = Map<String, dynamic>.from(event['data'] as Map? ?? {});
    switch (event['type']) {
      case 'room_state':
        applyRoom(LiveRoom.fromJson(Map<String, dynamic>.from(data['room'] as Map)));
      case 'participant_joined':
      case 'participant_updated':
      case 'participant_left':
      case 'waiting_requested':
      case 'waiting_resolved':
        unawaited(refresh());
      case 'room_ended':
        unawaited(cleanup());
        state = LiveRoomState.ended(meetingId: data['meetingId'] as String?);
      case 'connection_state':
        final connection = data['state'] as String;
        if (connection == 'removed' || connection == 'unauthorized') {
          unawaited(cleanup());
          state = const LiveRoomState.ended();
        } else {
          state = current.copyWith(connection: connection);
          if (connection == 'connected') unawaited(refresh());
        }
    }
  }

  void report(Object error) {
    final current = state;
    if (current is RoomActive) state = current.copyWith(error: failure(error));
  }

  void clearError() {
    final current = state;
    if (current is RoomActive) state = current.copyWith(error: null);
  }

  Future<bool> operation(Future<void> Function(RoomActive current) task) async {
    final current = state;
    if (current is! RoomActive || _operation) return false;
    _operation = true;
    state = current.copyWith(busy: true, error: null);
    final generation = _generation;
    try {
      await task(current);
      return true;
    } on Object catch (error) {
      if (generation == _generation) report(error);
      return false;
    } finally {
      _operation = false;
      final latest = state;
      if (generation == _generation && latest is RoomActive) state = latest.copyWith(busy: false);
    }
  }

  Future<void> connectMedia(Map<String, dynamic> config) {
    final pending = _mediaConnection;
    if (pending != null) return pending;
    final connection = _connectMedia(config);
    _mediaConnection = connection;
    return connection.whenComplete(() {
      if (identical(_mediaConnection, connection)) _mediaConnection = null;
    });
  }

  Future<void> _connectMedia(Map<String, dynamic> config) async {
    final current = state;
    if (current is! RoomActive) return;
    final generation = _generation;
    final released = _releaseTask;
    final cancel = DRCancelToken();
    _cancel = cancel;
    if (config['transport'] != 'dr-rtc') {
      state = current.copyWith(media: 'unavailable');
      return;
    }
    try {
      await released;
      if (!ref.mounted || generation != _generation || cancel.isCancelled) return;
      final settings = ref.read(appConfigProvider).live;
      final client = await rtcWait(
        ref.read(imClientProvider.future),
        cancel,
        Duration(milliseconds: settings.rtcReleaseTimeoutMs),
      );
      if (generation != _generation || cancel.isCancelled) return;
      if (!client.channels.supported) {
        state = (state as RoomActive).copyWith(media: 'unavailable');
        return;
      }
      final existing = await waitForRtcRelease(
        client.channels,
        cancel: cancel,
        timeout: Duration(milliseconds: settings.rtcReleaseTimeoutMs),
        pollInterval: Duration(milliseconds: settings.rtcReleasePollMs),
        onReleasing: () {
          final latest = state;
          if (generation == _generation && latest is RoomActive) {
            state = latest.copyWith(media: 'releasing', error: null);
          }
        },
      );
      if (generation != _generation || cancel.isCancelled) return;
      if (existing != null &&
          existing.status != 'left' &&
          (existing.channelId != config['channelId'] ||
              !['joining', 'joined'].contains(existing.status))) {
        throw DRException(
          code: LocalErrorCode.invalidState,
          details: const {'reason': 'media_resource_busy'},
          source: ErrorSource.local,
        );
      }
      state = (state as RoomActive).copyWith(media: 'connecting', error: null);
      final channel =
          existing != null &&
              existing.channelId == config['channelId'] &&
              ['joining', 'joined'].contains(existing.status)
          ? await client.channels.resume(
              channelId: existing.channelId,
              sessionId: existing.sessionId,
              cancel: cancel,
            )
          : await client.channels.join(
              config['channelId'] as String,
              options: ChannelJoinOptions(ticket: config['ticket'] as String, cancel: cancel),
            );
      if (generation != _generation || cancel.isCancelled) {
        await channel.leave();
        return;
      }
      _channel = channel;
      ref.read(roomChannelProvider.notifier).set(channel);
      _tracks = channel.currentTracks;
      _recorder?.resume();
      _audioTracks = channel.tracks.listen(
        (tracks) {
          if (generation != _generation) return;
          _tracks = tracks;
          syncRecording();
        },
        onError: (Object error) {
          if (generation == _generation) report(error);
        },
      );
      syncRecording();
      _mediaStates = channel.stream.listen((snapshot) {
        final latest = state;
        if (generation == _generation && latest is RoomActive) {
          state = latest.copyWith(media: snapshot.mediaState);
          if (snapshot.error != null) report(snapshot.error!);
        }
      });
      if (generation != _generation) return;
      if (_wantMic) {
        _wantMic = false;
        await mic(true);
      }
      if (generation == _generation && _wantCam) {
        _wantCam = false;
        await cam(true);
      }
    } on Object catch (error) {
      if (kDebugMode && error is DRException) {
        // Do not log credentials, request bodies or the SDK's full details map.
        debugPrint(
          'RTC connection failed: code=${error.code}, '
          'reason=${error.reason}, status=${error.status}',
        );
      }
      if (!ref.mounted || generation != _generation) return;
      final latest = state;
      if (latest is RoomActive) {
        state = latest.copyWith(media: 'error', error: failure(error));
      }
    }
  }

  Future<void> retryMedia() async {
    // The SDK owns one media resource. Overlapping retries can reserve multiple
    // platform sessions or fail locally with media_resource_busy.
    if (_retryingMedia || _mediaConnection != null) return;
    final current = state;
    if (current is RoomActive) {
      _retryingMedia = true;
      final generation = _generation;
      state = current.copyWith(media: 'connecting', error: null);
      try {
        final recorder = _recorder;
        await _releaseMedia();
        if (generation != _generation) return;
        await recorder?.finish();
        if (generation != _generation) return;
        ref.read(roomChannelProvider.notifier).set(null);
        final config = await _repo.media(current.room.id);
        if (generation != _generation) return;
        await connectMedia(config);
      } on Object catch (error) {
        final latest = state;
        if (generation == _generation && latest is RoomActive) {
          state = latest.copyWith(media: 'error', error: failure(error));
        }
      } finally {
        if (generation == _generation) _retryingMedia = false;
      }
    }
  }

  Future<bool> mic(bool enabled) => operation((current) async {
    if (enabled && current.self.mutedByHost) {
      throw const ApiException(kind: ApiErrorKind.forbidden);
    }
    final channel = ref.read(roomChannelProvider);
    if (channel == null) throw const ApiException(kind: ApiErrorKind.unavailable);
    await _repo.self(current.room.id, {'micOn': enabled});
    try {
      await channel.setMicrophoneEnabled(enabled);
    } on Object {
      await _repo.self(current.room.id, {'micOn': false});
      rethrow;
    }
    await refresh();
  });
  Future<bool> cam(bool enabled) => operation((current) async {
    final channel = ref.read(roomChannelProvider);
    if (channel == null) throw const ApiException(kind: ApiErrorKind.unavailable);
    await _repo.self(current.room.id, {'camOn': enabled});
    try {
      await setChannelCamera(channel, enabled);
    } on Object {
      await _repo.self(current.room.id, {'camOn': false});
      rethrow;
    }
    await refresh();
  });
  Future<bool> hand() => operation((current) async {
    if (current.self.isHost) throw const ApiException(kind: ApiErrorKind.forbidden);
    await _repo.self(current.room.id, {'handRaised': !current.self.handRaised});
    await refresh();
  });
  Future<bool> send(String text) => operation((current) async {
    await _repo.send(current.room.id, text);
    await refresh();
  });
  Future<bool> file() => operation((current) async {
    await _repo.pickAndSendFile(current.room.id);
    await refresh();
  });
  Future<bool> download(LiveAttachment file) =>
      operation((current) => _repo.download(current.room.id, file));
  Future<bool> action(String action, {String? participantId, Map<String, Object?>? values}) =>
      operation((current) async {
        if (action == 'transfer-host') await _recorder?.finish();
        try {
          if (participantId != null &&
              ['mute', 'approve-hand', 'remove', 'transfer-host'].contains(action)) {
            await _repo.participant(current.room.id, participantId, action, values: values);
          } else {
            await _repo.action(
              current.room.id,
              action,
              values: participantId == null ? values : {'participantId': participantId},
            );
          }
          await refresh();
        } on Object {
          if (action == 'transfer-host') _recorder?.resume();
          rethrow;
        }
      });
  Future<bool> settings(Map<String, Object?> values) => operation((current) async {
    applyRoom(await _repo.settings(current.room.id, values));
  });
  Future<bool> switchCamera() => operation((_) async {
    final channel = ref.read(roomChannelProvider);
    if (channel == null) throw const ApiException(kind: ApiErrorKind.unavailable);
    await switchChannelCamera(channel);
  });
  Future<bool> speaker(bool on) => operation((_) async {
    final channel = ref.read(roomChannelProvider);
    if (channel == null) throw const ApiException(kind: ApiErrorKind.unavailable);
    await channel.setSpeakerphoneOn(on);
  });

  void syncRecording() {
    final current = state;
    if (current is! RoomActive) return;
    final recording = current.room.recording;
    if (!current.self.isHost || recording == null || !recording.active) {
      final previous = _recorder;
      _recorder = null;
      if (previous != null) unawaited(previous.dispose());
      if (current.self.isHost) {
        if (recording == null) {
          state = current.copyWith(
            capture: 'error',
            captureError: 'automatic_recording_unavailable',
          );
        } else {
          unawaited(activateAutomaticRecording());
        }
      }
      return;
    }
    if (_recorder?.epoch != recording.epoch) {
      final previous = _recorder;
      if (previous != null) unawaited(previous.dispose());
      final config = ref.read(appConfigProvider);
      final repository = _repo;
      final generation = _generation;
      _recorder = RoomAudioRecorder(
        epoch: recording.epoch,
        startedAt: current.room.startedAt ?? recording.startedAt ?? DateTime.now(),
        source: ref.read(roomAudioSourceProvider),
        chunkMs: config.live.recordingChunkMs,
        maxPending: config.live.recordingMaxPending,
        frameTimeout: Duration(milliseconds: config.live.recordingFrameTimeoutMs),
        retryDelay: config.network.retry.delayFor(0),
        upload: (chunk) => repository.recordingChunk(current.room.id, chunk),
        report: (capture, error) {
          if (!ref.mounted) return;
          final latest = state;
          if (generation == _generation &&
              latest is RoomActive &&
              latest.room.recording?.epoch == recording.epoch &&
              latest.room.recording?.active == true) {
            state = latest.copyWith(capture: capture, captureError: error);
          }
        },
      );
    }
    _recorder?.sync(_tracks, {
      for (final member in current.room.participants)
        if (member.userId != null && member.micOn) member.userId!: member.id,
    });
  }

  /// Only compatibility activation for an older, inactive room. Manual stop and
  /// approvals are no longer part of the automatic recording protocol.
  Future<void> activateAutomaticRecording({bool retry = false}) async {
    final current = state;
    if (current is! RoomActive ||
        !current.self.isHost ||
        current.room.recording == null ||
        current.room.recording!.active ||
        _activatingRecording) {
      return;
    }
    final key = '${current.room.id}:${current.room.recording!.epoch}';
    if (!retry && _activationAttempt == key) return;
    _activationAttempt = key;
    _activatingRecording = true;
    final generation = _generation;
    try {
      final room = await _repo.controlRecording(current.room.id, {
        'action': 'start',
        'epoch': current.room.recording!.epoch,
      });
      if (generation == _generation) applyRoom(room);
    } on Object catch (error) {
      final latest = state;
      if (generation == _generation && latest is RoomActive) {
        state = latest.copyWith(capture: 'error', captureError: failure(error));
      }
    } finally {
      _activatingRecording = false;
    }
  }

  Future<bool> retryRecording() => operation((_) async {
    await activateAutomaticRecording(retry: true);
    await _recorder?.retry();
    _recorder?.resume();
  });
  Future<bool> leave({bool end = false}) async {
    final current = state;
    final room = switch (current) {
      RoomActive(:final room) => room,
      RoomWaiting(:final room) => room,
      _ => null,
    };
    if (room == null || _operation) return false;
    _operation = true;
    if (current is RoomActive) state = current.copyWith(busy: true, error: null);
    try {
      if (end) await _recorder?.finish();
      final meetingId = end ? await _repo.end(room.id) : null;
      if (!end) await _repo.action(room.id, 'leave');
      ref.read(meetingsChangedProvider.notifier).bump();
      ref.invalidate(liveSchedulesProvider);
      ref.invalidate(upcomingSchedulesProvider);
      unawaited(cleanup());
      state = LiveRoomState.ended(meetingId: meetingId);
      return true;
    } on Object catch (error) {
      if (current is RoomActive) {
        _recorder?.resume();
        report(error);
      } else if (current is RoomWaiting) {
        state = current.copyWith(error: failure(error));
      }
      return false;
    } finally {
      _operation = false;
      final latest = state;
      if (latest is RoomActive) state = latest.copyWith(busy: false);
    }
  }

  void reset() {
    unawaited(cleanup());
    state = const LiveRoomState.idle();
  }
}
