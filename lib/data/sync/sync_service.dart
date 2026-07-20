import 'dart:async';

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

  const SyncOutcome._(this.success, this.permanent,
      {this.collection, this.remapFromId, this.remapToId, this.realDoc});

  /// Applied; optionally reconcile a temp id to the server id.
  const SyncOutcome.done({String? collection, String? remapFromId, String? remapToId, Map<String, dynamic>? realDoc})
      : this._(true, false, collection: collection, remapFromId: remapFromId, remapToId: remapToId, realDoc: realDoc);

  /// Transient failure (offline / server down) — keep and retry later.
  const SyncOutcome.retry() : this._(false, false);

  /// Permanent failure (bad request) — drop the mutation.
  const SyncOutcome.drop() : this._(false, true);
}

typedef MutationHandler = Future<SyncOutcome> Function(AuthenticatedClient client, Mutation m);

/// Drains the outbox against the backend whenever the app is online. Handlers
/// are registered per mutation kind by the offline-first repositories.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final LocalStore _store = LocalStore.instance;
  final _handlers = <String, MutationHandler>{};

  AuthenticatedClient? _client;
  StreamSubscription<bool>? _sub;
  bool _flushing = false;

  void registerHandler(String kind, MutationHandler handler) => _handlers[kind] = handler;

  /// Wire up the authenticated client and start reacting to connectivity.
  /// Safe to call once the client exists (e.g. from the app's initState).
  void bind(AuthenticatedClient client) {
    _client = client;
    _sub ??= ConnectivityService.instance.onlineChanges.listen((online) {
      if (online) flush();
    });
    flush();
  }

  /// Fire-and-forget flush (used right after enqueuing a mutation).
  void flushSoon() => unawaited(flush());

  /// Replays pending mutations in order. Stops at the first transient failure so
  /// ordering and idempotency are preserved; drops permanent failures.
  Future<void> flush() async {
    final client = _client;
    if (client == null || _flushing || !_store.isReady) return;
    if (!await ConnectivityService.instance.isOnline()) return;
    _flushing = true;
    try {
      for (final m in _store.pending()) {
        final handler = _handlers[m.kind];
        if (handler == null) {
          await _store.removeMutation(m.id); // unknown kind — can't replay
          continue;
        }
        final out = await handler(client, m);
        if (out.success) {
          if (out.remapFromId != null && out.remapToId != null && out.collection != null) {
            await _store.remapId(out.collection!, out.remapFromId!, out.remapToId!, out.realDoc ?? const {});
          }
          await _store.removeMutation(m.id);
        } else if (out.permanent) {
          await _store.removeMutation(m.id);
        } else {
          m.retries += 1;
          await _store.updateMutation(m);
          break; // transient — retry the whole queue later, in order
        }
      }
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
