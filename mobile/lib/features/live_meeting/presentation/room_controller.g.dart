// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(roomAudioSource)
final roomAudioSourceProvider = RoomAudioSourceProvider._();

final class RoomAudioSourceProvider
    extends
        $FunctionalProvider<RoomAudioSource, RoomAudioSource, RoomAudioSource>
    with $Provider<RoomAudioSource> {
  RoomAudioSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomAudioSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomAudioSourceHash();

  @$internal
  @override
  $ProviderElement<RoomAudioSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoomAudioSource create(Ref ref) {
    return roomAudioSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomAudioSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomAudioSource>(value),
    );
  }
}

String _$roomAudioSourceHash() => r'850d3df685c3fa26b7401b6d0f8697512692cdef';

/// The app keeps this provider alive for the entire admitted room lifetime,
/// including while its chat sheet is closed or the room page is minimized.

@ProviderFor(roomChatLifecycle)
final roomChatLifecycleProvider = RoomChatLifecycleProvider._();

/// The app keeps this provider alive for the entire admitted room lifetime,
/// including while its chat sheet is closed or the room page is minimized.

final class RoomChatLifecycleProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// The app keeps this provider alive for the entire admitted room lifetime,
  /// including while its chat sheet is closed or the room page is minimized.
  RoomChatLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomChatLifecycleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomChatLifecycleHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return roomChatLifecycle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$roomChatLifecycleHash() => r'd245a1bc528ed667fc186f9cdd81fd4bcdb2d137';

@ProviderFor(roomChatSession)
final roomChatSessionProvider = RoomChatSessionProvider._();

final class RoomChatSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConversationView>,
          ConversationView,
          FutureOr<ConversationView>
        >
    with $FutureModifier<ConversationView>, $FutureProvider<ConversationView> {
  RoomChatSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomChatSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomChatSessionHash();

  @$internal
  @override
  $FutureProviderElement<ConversationView> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConversationView> create(Ref ref) {
    return roomChatSession(ref);
  }
}

String _$roomChatSessionHash() => r'b1d1b8930ccdb7c4a64a3c00074cd5390f9f5063';

@ProviderFor(RoomChannel)
final roomChannelProvider = RoomChannelProvider._();

final class RoomChannelProvider
    extends $NotifierProvider<RoomChannel, ChannelHandle?> {
  RoomChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomChannelHash();

  @$internal
  @override
  RoomChannel create() => RoomChannel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelHandle? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelHandle?>(value),
    );
  }
}

String _$roomChannelHash() => r'08b8bdbcc1c3d10c55a59307ea7622366de6dba5';

abstract class _$RoomChannel extends $Notifier<ChannelHandle?> {
  ChannelHandle? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChannelHandle?, ChannelHandle?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChannelHandle?, ChannelHandle?>,
              ChannelHandle?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(RoomController)
final roomControllerProvider = RoomControllerProvider._();

final class RoomControllerProvider
    extends $NotifierProvider<RoomController, LiveRoomState> {
  RoomControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomControllerHash();

  @$internal
  @override
  RoomController create() => RoomController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveRoomState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveRoomState>(value),
    );
  }
}

String _$roomControllerHash() => r'dc01394e70ef0fb205dacd87b5c224a80dfd83e6';

abstract class _$RoomController extends $Notifier<LiveRoomState> {
  LiveRoomState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LiveRoomState, LiveRoomState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LiveRoomState, LiveRoomState>,
              LiveRoomState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
