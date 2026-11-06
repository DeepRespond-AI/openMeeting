// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_info_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds the [ClientInfo] sent with login/register and the heartbeat:
/// client id (SessionStore), device model as hostname, os, app version.

@ProviderFor(clientInfo)
final clientInfoProvider = ClientInfoProvider._();

/// Builds the [ClientInfo] sent with login/register and the heartbeat:
/// client id (SessionStore), device model as hostname, os, app version.

final class ClientInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClientInfo>,
          ClientInfo,
          FutureOr<ClientInfo>
        >
    with $FutureModifier<ClientInfo>, $FutureProvider<ClientInfo> {
  /// Builds the [ClientInfo] sent with login/register and the heartbeat:
  /// client id (SessionStore), device model as hostname, os, app version.
  ClientInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientInfoHash();

  @$internal
  @override
  $FutureProviderElement<ClientInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ClientInfo> create(Ref ref) {
    return clientInfo(ref);
  }
}

String _$clientInfoHash() => r'b14fd5e89aed23f835231e6d900564563a26eb4f';
