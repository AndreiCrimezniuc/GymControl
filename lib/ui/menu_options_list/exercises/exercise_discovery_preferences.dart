import 'package:shared_preferences/shared_preferences.dart';

/// Device-local discovery state. Recent choices and favorites are UX hints,
/// not workout data, so they remain useful offline and don't need server sync.
class ExerciseDiscoveryPreferences {
  static const _recentKey = 'exercise_discovery_recent_ids';
  static const _favoriteKey = 'exercise_discovery_favorite_ids';
  static const recentLimit = 20;

  Future<List<int>> recentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getStringList(_recentKey));
  }

  Future<Set<int>> favoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getStringList(_favoriteKey)).toSet();
  }

  Future<void> recordRecent(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _decode(prefs.getStringList(_recentKey));
    ids
      ..remove(id)
      ..insert(0, id);
    await prefs.setStringList(
      _recentKey,
      ids.take(recentLimit).map((value) => '$value').toList(),
    );
  }

  Future<Set<int>> toggleFavorite(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _decode(prefs.getStringList(_favoriteKey)).toSet();
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    await prefs.setStringList(
      _favoriteKey,
      ids.map((value) => '$value').toList()..sort(),
    );
    return ids;
  }

  List<int> _decode(List<String>? values) =>
      (values ?? const <String>[]).map(int.tryParse).whereType<int>().toList();
}
