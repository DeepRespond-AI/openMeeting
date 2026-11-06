// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_player_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
/// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
/// Speeds and skip step come from `AppConfig.player`.

@ProviderFor(MeetingPlayerController)
final meetingPlayerControllerProvider = MeetingPlayerControllerFamily._();

/// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
/// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
/// Speeds and skip step come from `AppConfig.player`.
final class MeetingPlayerControllerProvider
    extends $NotifierProvider<MeetingPlayerController, MeetingPlayerState> {
  /// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
  /// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
  /// Speeds and skip step come from `AppConfig.player`.
  MeetingPlayerControllerProvider._({
    required MeetingPlayerControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'meetingPlayerControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$meetingPlayerControllerHash();

  @override
  String toString() {
    return r'meetingPlayerControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MeetingPlayerController create() => MeetingPlayerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeetingPlayerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingPlayerControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$meetingPlayerControllerHash() =>
    r'f0f2477efa71087feac89285ccbb2a16169a22d7';

/// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
/// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
/// Speeds and skip step come from `AppConfig.player`.

final class MeetingPlayerControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MeetingPlayerController,
          MeetingPlayerState,
          MeetingPlayerState,
          MeetingPlayerState,
          String
        > {
  MeetingPlayerControllerFamily._()
    : super(
        retry: null,
        name: r'meetingPlayerControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
  /// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
  /// Speeds and skip step come from `AppConfig.player`.

  MeetingPlayerControllerProvider call(String meetingId) =>
      MeetingPlayerControllerProvider._(argument: meetingId, from: this);

  @override
  String toString() => r'meetingPlayerControllerProvider';
}

/// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
/// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
/// Speeds and skip step come from `AppConfig.player`.

abstract class _$MeetingPlayerController extends $Notifier<MeetingPlayerState> {
  late final _$args = ref.$arg as String;
  String get meetingId => _$args;

  MeetingPlayerState build(String meetingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MeetingPlayerState, MeetingPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MeetingPlayerState, MeetingPlayerState>,
              MeetingPlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
