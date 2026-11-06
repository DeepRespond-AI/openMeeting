import 'dart:io';

import 'package:app_installer/app_installer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'update_installer.g.dart';

/// Platform side of an update: install a downloaded APK (Android `direct` build) or open the
/// store page (store channels, iOS). Behind an interface so tests use a fake.
abstract interface class UpdateInstaller {
  /// Android 8+: whether the user allowed this app to install packages.
  Future<bool> canInstallPackages();

  Future<void> openInstallSettings();

  Future<void> installApk(String path);

  /// Opens [url] in the store app (or browser); false when nothing could open it.
  Future<bool> openStore(String url);

  /// Where the APK is downloaded (shared with the installer through a FileProvider).
  Future<Directory> downloadDir();
}

class PlatformUpdateInstaller implements UpdateInstaller {
  PlatformUpdateInstaller([AppInstaller? installer]) : _installer = installer ?? AppInstaller();

  final AppInstaller _installer;

  @override
  Future<bool> canInstallPackages() => _installer.canInstallPackages();

  @override
  Future<void> openInstallSettings() => _installer.openInstallSettings();

  @override
  Future<void> installApk(String path) => _installer.installApk(path);

  @override
  Future<bool> openStore(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Future.value(false);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<Directory> downloadDir() => getTemporaryDirectory();
}

@Riverpod(keepAlive: true)
UpdateInstaller updateInstaller(Ref ref) => PlatformUpdateInstaller();
