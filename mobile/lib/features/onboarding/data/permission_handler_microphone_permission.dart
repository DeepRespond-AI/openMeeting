import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/microphone_permission.dart';

part 'permission_handler_microphone_permission.g.dart';

/// [MicrophonePermissionRepository] backed by `permission_handler`.
class PermissionHandlerMicrophonePermission implements MicrophonePermissionRepository {
  const PermissionHandlerMicrophonePermission();

  static MicPermission _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => MicPermission.granted,
    PermissionStatus.permanentlyDenied => MicPermission.permanentlyDenied,
    PermissionStatus.restricted => MicPermission.restricted,
    PermissionStatus.denied => MicPermission.denied,
  };

  @override
  Future<MicPermission> status() async => _map(await Permission.microphone.status);

  @override
  Future<MicPermission> request() async => _map(await Permission.microphone.request());

  @override
  Future<bool> openSystemSettings() => openAppSettings();
}

@Riverpod(keepAlive: true)
MicrophonePermissionRepository microphonePermissionRepository(Ref ref) =>
    const PermissionHandlerMicrophonePermission();
