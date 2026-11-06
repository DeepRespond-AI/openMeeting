import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../api/models/auth_models.dart';
import 'session_store.dart';

part 'client_info_source.g.dart';

/// `os` values sent to the server.
abstract final class ClientOs {
  static const String android = 'android';
  static const String ios = 'ios';

  static String get current => Platform.isIOS ? ios : android;
}

/// Builds the [ClientInfo] sent with login/register and the heartbeat:
/// client id (SessionStore), device model as hostname, os, app version.
@Riverpod(keepAlive: true)
Future<ClientInfo> clientInfo(Ref ref) async {
  final store = ref.watch(sessionStoreProvider);
  final clientId = await store.clientId();
  final package = await PackageInfo.fromPlatform();
  final device = DeviceInfoPlugin();
  final String hostname;
  if (Platform.isIOS) {
    final ios = await device.iosInfo;
    hostname = ios.modelName.isNotEmpty ? ios.modelName : ios.model;
  } else if (Platform.isAndroid) {
    final android = await device.androidInfo;
    hostname = '${android.manufacturer} ${android.model}'.trim();
  } else {
    hostname = Platform.localHostname;
  }
  final build = package.buildNumber;
  return ClientInfo(
    clientId: clientId,
    hostname: hostname,
    os: ClientOs.current,
    appVersion: build.isEmpty ? package.version : '${package.version}+$build',
  );
}
