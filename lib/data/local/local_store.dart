import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:gymboss/data/local/mutation.dart';

/// Offline-first storage: a document cache (server JSON keyed by collection+id),
/// ordered list snapshots (list endpoints keyed by a name), and an outbox of
/// pending mutations. Backed by Hive so it works on iOS, Android and web without
/// codegen. Values are stored as JSON strings for portability.
///
/// A process-wide singleton so repositories constructed ad-hoc in widgets can
/// share one store without threading it through the widget tree.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  late Box<String> _docs;
  late Box<String> _lists;
  late Box<String> _outbox;
  bool _ready = false;

  bool get isReady => _ready;

  /// Opens the boxes. Pass [path] in tests (uses Hive.init); production passes
  /// nothing and uses Hive.initFlutter (app documents dir).
  Future<void> init({String? path}) async {
    if (_ready) return;
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter('gymboss_offline');
    }
    _docs = await Hive.openBox<String>('docs');
    _lists = await Hive.openBox<String>('lists');
    _outbox = await Hive.openBox<String>('outbox');
    _ready = true;
  }

  String _docKey(String collection, String id) => '$collection/$id';

  // ── Documents ────────────────────────────────────────────────────────────

  Map<String, dynamic>? getDoc(String collection, String id) {
    final s = _docs.get(_docKey(collection, id));
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> putDoc(
    String collection,
    String id,
    Map<String, dynamic> body,
  ) => _docs.put(_docKey(collection, id), jsonEncode(body));

  Future<void> deleteDoc(String collection, String id) =>
      _docs.delete(_docKey(collection, id));

  // ── Ordered list snapshots ───────────────────────────────────────────────

  bool hasList(String key) => _lists.containsKey(key);

  List<String> getListIds(String key) {
    final s = _lists.get(key);
    return s == null ? const [] : (jsonDecode(s) as List).cast<String>();
  }

  Future<void> putListIds(String key, List<String> ids) =>
      _lists.put(key, jsonEncode(ids));

  /// Hydrates a list snapshot into the documents it references (skipping any
  /// that were evicted).
  List<Map<String, dynamic>> getListDocs(String collection, String key) =>
      getListIds(key)
          .map((id) => getDoc(collection, id))
          .whereType<Map<String, dynamic>>()
          .toList();

  Future<void> prependToList(String key, String id) async {
    final ids = getListIds(key).toList()..remove(id);
    await putListIds(key, [id, ...ids]);
  }

  Future<void> removeFromList(String key, String id) async {
    final ids = getListIds(key).toList()..remove(id);
    await putListIds(key, ids);
  }

  // ── Outbox ───────────────────────────────────────────────────────────────

  Future<void> enqueue(Mutation m) => _outbox.put(m.id, jsonEncode(m.toJson()));

  Future<void> updateMutation(Mutation m) => enqueue(m);

  Future<void> removeMutation(String id) => _outbox.delete(id);

  /// Pending mutations in application (seq) order.
  List<Mutation> pending() {
    final list =
        _outbox.values
            .map(
              (s) => Mutation.fromJson(jsonDecode(s) as Map<String, dynamic>),
            )
            .toList();
    list.sort((a, b) => a.seq.compareTo(b.seq));
    return list;
  }

  bool get hasPending => _outbox.isNotEmpty;

  /// Monotonic sequence for ordering new mutations.
  int nextSeq() => DateTime.now().microsecondsSinceEpoch;

  // ── Temp-id reconciliation ───────────────────────────────────────────────

  /// After an offline-created entity is accepted by the server, swap its
  /// temporary id for the real one across the document cache, every list
  /// snapshot, and the args of any still-pending mutation that referenced it.
  Future<void> remapId(
    String collection,
    String fromId,
    String toId,
    Map<String, dynamic> realDoc,
  ) async {
    await deleteDoc(collection, fromId);
    await putDoc(collection, toId, realDoc);
    for (final key in _lists.keys.cast<String>()) {
      final ids = getListIds(key);
      if (ids.contains(fromId)) {
        await putListIds(key, ids.map((e) => e == fromId ? toId : e).toList());
      }
    }
    for (final m in pending()) {
      if (m.args['id'] == fromId) {
        m.args['id'] = toId;
        await updateMutation(m);
      }
    }
  }

  /// Cancels every pending mutation targeting a temp id (used when an
  /// offline-created entity is deleted before it ever reached the server).
  Future<void> cancelPendingFor(String tempId) async {
    for (final m in pending()) {
      if (m.args['id'] == tempId || m.args['tempId'] == tempId) {
        await removeMutation(m.id);
      }
    }
  }

  /// Test/reset helper.
  Future<void> clear() async {
    await _docs.clear();
    await _lists.clear();
    await _outbox.clear();
  }
}
