/// A pending local change that must be replayed against the backend once the
/// device is online. Stored in the outbox and applied in `seq` order.
class Mutation {
  final String id; // unique (uuid)
  final int seq; // monotonic ordering key
  final String
  kind; // e.g. 'workout.create' | 'workout.update' | 'workout.delete'
  final Map<String, dynamic> args; // handler-specific payload
  int retries;

  Mutation({
    required this.id,
    required this.seq,
    required this.kind,
    required this.args,
    this.retries = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'seq': seq,
    'kind': kind,
    'args': args,
    'retries': retries,
  };

  factory Mutation.fromJson(Map<String, dynamic> j) => Mutation(
    id: j['id'] as String,
    seq: (j['seq'] as num).toInt(),
    kind: j['kind'] as String,
    args: Map<String, dynamic>.from(j['args'] as Map),
    retries: (j['retries'] as num?)?.toInt() ?? 0,
  );
}
