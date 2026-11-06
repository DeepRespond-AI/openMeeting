import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im_flutter/deeprespond_im_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/endpoints.dart';
import '../auth/session_controller.dart';
import '../config/app_config_provider.dart';
part 'im_gateway.g.dart';

@Riverpod(keepAlive: true)
DRPlatform imPlatform(Ref ref) => DRFlutterPlatform.instance;

@Riverpod(keepAlive: true)
ImGateway imGateway(Ref ref) {
  String? identity() => switch (ref.read(sessionControllerProvider).value) {
    AuthSignedIn(:final user) => user.id,
    _ => null,
  };
  final gateway = ImGateway(
    identity,
    () => apiCall(() async {
      final response = await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>(Endpoints.imTicket);
      return response.data!;
    }),
    ref.watch(imPlatformProvider),
    ref.watch(appConfigProvider).network.requestTimeout,
  );
  ref.listen(sessionControllerProvider, (previous, next) {
    final before = switch (previous?.value) {
      AuthSignedIn(:final user) => user.id,
      _ => null,
    };
    final after = switch (next.value) {
      AuthSignedIn(:final user) => user.id,
      _ => null,
    };
    if (before != after) unawaited(gateway.logout());
  });
  ref.onDispose(() => unawaited(gateway.logout()));
  return gateway;
}

@Riverpod(keepAlive: true)
Future<DRClient> imClient(Ref ref) async {
  final auth = ref.watch(sessionControllerProvider).value;
  if (auth is! AuthSignedIn) throw const ApiException(kind: ApiErrorKind.unauthorized);
  return ref.watch(imGatewayProvider).ensure(auth.user.id);
}

/// The SDK is process-wide. Serialize identity changes and never reuse another
/// business user's SDK session or ticket renewal callback.
class ImGateway {
  ImGateway(this.identity, this.ticket, this.platform, this.readyTimeout);
  final String? Function() identity;
  final Future<Map<String, dynamic>> Function() ticket;
  final DRPlatform platform;
  final Duration readyTimeout;
  DRClient? _client;
  String? _configuration;
  Future<void> _queue = Future.value();
  Future<T> serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}).catchError((Object _) {});
    return result;
  }

  Future<DRClient> ensure(String userId) => serialized(() async {
    if (identity() != userId) throw const ApiException(kind: ApiErrorKind.unauthorized);
    final bootstrap = await ticket();
    if (identity() != userId) throw const ApiException(kind: ApiErrorKind.unauthorized);
    final key = bootstrap['app_key'] as String, url = bootstrap['api_url'] as String;
    if (_configuration != null && _configuration != '$key|$url') {
      throw const ApiException(kind: ApiErrorKind.conflict);
    }
    _client ??= await DRClient.create(
      DRClientOptions(
        appKey: key,
        apiUrl: Uri.parse(url),
        platform: platform,
        ticketProvider: (_) async {
          final current = identity();
          if (current == null || _client?.auth.currentUser?.username != current) {
            throw const ApiException(kind: ApiErrorKind.unauthorized);
          }
          return (await ticket())['ticket'] as String;
        },
      ),
    );
    _configuration = '$key|$url';
    final client = _client!;
    if (client.auth.currentUser != null && client.auth.currentUser!.username != userId) {
      await client.auth.logout();
    }
    if (identity() != userId) throw const ApiException(kind: ApiErrorKind.unauthorized);
    if (client.auth.currentUser == null) {
      await client.auth.loginWithTicket(ticket: bootstrap['ticket'] as String);
    }
    if (identity() != userId) {
      await client.auth.logout();
      throw const ApiException(kind: ApiErrorKind.unauthorized);
    }
    await client.connection.waitUntilReady(timeout: readyTimeout);
    return client;
  });
  Future<void> logout() => serialized(() async {
    try {
      await _client?.channels.current?.leave();
    } finally {
      await _client?.auth.logout();
    }
  });
}
