import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over connectivity_plus exposing a simple online/offline signal.
/// Connectivity is not the same as reachability, but it's a good-enough trigger
/// for "try flushing the outbox now".
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();

  static bool _online(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  /// Emits whenever the online/offline state changes.
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}
