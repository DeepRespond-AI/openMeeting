// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authorizedTracks)
final authorizedTracksProvider = AuthorizedTracksProvider._();

final class AuthorizedTracksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChannelTrack>>,
          List<ChannelTrack>,
          Stream<List<ChannelTrack>>
        >
    with
        $FutureModifier<List<ChannelTrack>>,
        $StreamProvider<List<ChannelTrack>> {
  AuthorizedTracksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authorizedTracksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authorizedTracksHash();

  @$internal
  @override
  $StreamProviderElement<List<ChannelTrack>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChannelTrack>> create(Ref ref) {
    return authorizedTracks(ref);
  }
}

String _$authorizedTracksHash() => r'0d5b9c792ef7196d057e671dba27f44002373850';
