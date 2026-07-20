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

  Future<bool> isOnline() async {
    try {
      return _online(await _connectivity.checkConnectivity());
    } on Object {
      // Connectivity is only a retry hint, never a source of truth. If the
      // platform plugin is unavailable, attempt the request and let the HTTP
      // layer classify reachability.
      return true;
    }
  }

  /// Emits whenever the online/offline state changes.
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}
