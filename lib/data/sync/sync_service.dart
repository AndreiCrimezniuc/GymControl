import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:gymboss/data/local/local_store.dart';
import 'package:gymboss/data/local/mutation.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/connectivity_service.dart';

/// Result of replaying one mutation against the backend.
class SyncOutcome {
  final bool success; // accepted by the server; remove from outbox
  final bool permanent; // client error (4xx) that will never succeed; drop
  final String? collection; // for id remap after an offline create
  final String? remapFromId;
  final String? remapToId;
  final Map<String, dynamic>? realDoc;

  const SyncOutcome._(
    this.success,
    this.permanent, {
    this.collection,
    this.remapFromId,
    this.remapToId,
    this.realDoc,
  });

  /// Applied; optionally reconcile a temp id to the server id.
  const SyncOutcome.done({
    String? collection,
    String? remapFromId,
    String? remapToId,
    Map<String, dynamic>? realDoc,
  }) : this._(
         true,
         false,
         collection: collection,
         remapFromId: remapFromId,
         remapToId: remapToId,
         realDoc: realDoc,
       );

  /// Transient failure (offline / server down) — keep and retry later.
  const SyncOutcome.retry() : this._(false, false);

  /// Permanent failure (bad request) — drop the mutation.
  const SyncOutcome.drop() : this._(false, true);
}

typedef MutationHandler =
    Future<SyncOutcome> Function(AuthenticatedClient client, Mutation m);

/// A snapshot of sync health for the UI: whether the device is online and how
/// many local changes are still waiting to reach the backend.
@immutable
class SyncStatus {
  final bool online;
  final int pending;
  const SyncStatus({required this.online, required this.pending});

  bool get hasPending => pending > 0;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus && other.online == online && other.pending == pending;

  @override
  int get hashCode => Object.hash(online, pending);
}

/// Drains the outbox against the backend whenever the app is online. Handlers
/// are registered per mutation kind by the offline-first repositories.
class SyncService {
  SyncService({
    LocalStore? store,
    Future<bool> Function()? isOnline,
    Stream<bool>? onlineChanges,
  }) : _store = store ?? LocalStore.instance,
       _isOnline = isOnline ?? ConnectivityService.instance.isOnline,
       _onlineChanges =
           onlineChanges ?? ConnectivityService.instance.onlineChanges;

  static final SyncService instance = SyncService();

  final LocalStore _store;
  final Future<bool> Function() _isOnline;
  final Stream<bool> _onlineChanges;
  final _handlers = <String, MutationHandler>{};

  AuthenticatedClient? _client;
  StreamSubscription<bool>? _sub;
  bool _flushing = false;
  bool _online = true;

  /// Reactive sync health for the UI (online state + pending-change count).
  /// Repositories call [notifyChanged] after enqueuing; connectivity and flush
  /// update it automatically.
  final ValueNotifier<SyncStatus> status = ValueNotifier(
    const SyncStatus(online: true, pending: 0),
  );

  /// Recomputes [status] from the current online flag and outbox depth.
  void notifyChanged() {
    final pending = _store.isReady ? _store.pending().length : 0;
    status.value = SyncStatus(online: _online, pending: pending);
  }

  void registerHandler(String kind, MutationHandler handler) {
    _handlers[kind] = handler;
    // bind() can run before repositories are constructed. A pending queue must
    // stay intact until its handler exists, then it can be retried safely.
    flushSoon();
  }

  /// Wire up the authenticated client and start reacting to connectivity.
  /// Safe to call once the client exists (e.g. from the app's initState).
  void bind(AuthenticatedClient client) {
    _client = client;
    _sub ??= _onlineChanges.listen((online) {
      _online = online;
      notifyChanged();
      if (online) flush();
    });
    unawaited(
      _isOnline().then((v) {
        _online = v;
        notifyChanged();
      }),
    );
    flush();
  }

  /// Fire-and-forget flush (used right after enqueuing a mutation).
  void flushSoon() => unawaited(flush());

  /// Replays pending mutations in order. Stops at the first transient failure so
  /// ordering and idempotency are preserved; drops permanent failures.
  Future<void> flush() async {
    final client = _client;
    // Keep the UI's pending count fresh even when we can't drain right now
    // (offline, or an enqueue happened while another flush is in flight).
    notifyChanged();
    if (client == null || _flushing || !_store.isReady) return;
    if (!await _isOnline()) return;
    _flushing = true;
    try {
      for (final m in _store.pending()) {
        final handler = _handlers[m.kind];
        if (handler == null) {
          // Repositories register handlers lazily. Never discard durable user
          // work merely because app startup has not constructed one yet.
          break;
        }
        SyncOutcome out;
        try {
          out = await handler(client, m);
        } on Object {
          // A buggy handler or an unexpected parsing error must not destroy the
          // outbox. Preserve ordering and retry after the next trigger.
          out = const SyncOutcome.retry();
        }
        if (out.success) {
          if (out.remapFromId != null &&
              out.remapToId != null &&
              out.collection != null) {
            await _store.remapId(
              out.collection!,
              out.remapFromId!,
              out.remapToId!,
              out.realDoc ?? const {},
            );
          }
          await _store.removeMutation(m.id);
        } else if (out.permanent) {
          // Keep rejected mutations as a durable dead-letter instead of
          // silently losing the user's offline change. A future UI can expose
          // and resolve it; later mutations must not overtake it.
          m.retries += 1;
          await _store.updateMutation(m);
          break;
        } else {
          m.retries += 1;
          await _store.updateMutation(m);
          break; // transient — retry the whole queue later, in order
        }
      }
    } finally {
      _flushing = false;
      notifyChanged();
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    status.dispose();
  }
}
