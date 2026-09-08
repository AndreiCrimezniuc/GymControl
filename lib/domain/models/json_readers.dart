/// Defensive readers for persisted and server-provided JSON.
///
/// Mobile clients can keep cached documents across many backend versions. A
/// malformed legacy child must not make an otherwise valid screen unusable.
Map<String, dynamic>? jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

List<T> jsonObjectList<T>(
  Object? value,
  T Function(Map<String, dynamic>) decode, {
  int maxItems = 10000,
}) {
  if (value is! List) return <T>[];
  final result = <T>[];
  for (final item in value.take(maxItems)) {
    final map = jsonMap(item);
    if (map == null) continue;
    try {
      result.add(decode(map));
    } catch (_) {
      // Isolate a bad legacy/cache entry instead of losing the entire list.
    }
  }
  return result;
}

String jsonString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

String? jsonNullableString(Object? value) => value is String ? value : null;

bool jsonBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

double jsonDouble(
  Object? value, {
  double fallback = 0,
  double? min,
  double? max,
}) {
  if (value is! num) return fallback;
  final parsed = value.toDouble();
  if (!parsed.isFinite) return fallback;
  if (min != null && parsed < min) return min;
  if (max != null && parsed > max) return max;
  return parsed;
}

double? jsonNullableDouble(Object? value, {double? min, double? max}) {
  if (value == null || value is! num || !value.toDouble().isFinite) return null;
  return jsonDouble(value, min: min, max: max);
}

int jsonInt(Object? value, {int fallback = 0, int? min, int? max}) {
  if (value is! num || !value.toDouble().isFinite) return fallback;
  final parsed = value.toInt();
  if (min != null && parsed < min) return min;
  if (max != null && parsed > max) return max;
  return parsed;
}

int? jsonNullableInt(Object? value, {int? min, int? max}) {
  if (value == null || value is! num || !value.toDouble().isFinite) return null;
  return jsonInt(value, min: min, max: max);
}

List<String> jsonStringList(Object? value, {int maxItems = 1000}) =>
    value is List
    ? value.whereType<String>().take(maxItems).toList(growable: false)
    : const <String>[];
