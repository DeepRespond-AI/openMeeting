/// Hands a downloaded APK to the Android package installer (in-app updates).
library;

import 'dart:io';

import 'package:flutter/services.dart';

class AppInstaller {
  AppInstaller({MethodChannel? channel}) : _channel = channel ?? defaultChannel;

  static const MethodChannel defaultChannel = MethodChannel(
    'cn.deeprespond.app_installer',
  );

  final MethodChannel _channel;

  /// Whether the user allowed this app to install packages (always true before Android 8).
  Future<bool> canInstallPackages() async {
    _requireAndroid();
    return await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
  }

  /// Opens the system "install unknown apps" setting for this app.
  Future<void> openInstallSettings() async {
    _requireAndroid();
    await _channel.invokeMethod<void>('openInstallSettings');
  }

  /// Starts the system installer for the APK at [path] (must be inside the app cache dir).
  Future<void> installApk(String path) async {
    _requireAndroid();
    await _channel.invokeMethod<void>('installApk', {'path': path});
  }

  static void _requireAndroid() {
    if (!Platform.isAndroid) {
      throw UnsupportedError('APK installation is Android-only');
    }
  }
}
