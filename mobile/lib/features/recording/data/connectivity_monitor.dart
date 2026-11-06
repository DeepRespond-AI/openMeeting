import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_monitor.g.dart';

/// Network reachability changes (used to flush the pending segment queue).
abstract interface class ConnectivityMonitor {
  /// Emits `true` when a network becomes available, `false` when it is lost.
  Stream<bool> get onlineChanges;
}

class PluginConnectivityMonitor implements ConnectivityMonitor {
  PluginConnectivityMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none))
      .distinct();
}

@Riverpod(keepAlive: true)
ConnectivityMonitor connectivityMonitor(Ref ref) => PluginConnectivityMonitor();
