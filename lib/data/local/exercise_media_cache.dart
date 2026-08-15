import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/domain/models/exercises/exercise_catalog.dart';

/// Warms the persistent image cache for the complete curated catalog.
///
/// Four workers keep first-run bandwidth controlled while ensuring every
/// exercise illustration remains available after the device goes offline.
abstract final class ExerciseMediaCache {
  static Future<void> warm(Iterable<ExerciseCatalogItem> exercises) async {
    final urls = exercises
        .expand((exercise) => [exercise.imageUrl, exercise.imageUrl2])
        .where((url) => url.trim().isNotEmpty)
        .map(ApiConfig.resolveImageUrl)
        .toSet()
        .toList(growable: false);
    var cursor = 0;

    Future<void> worker() async {
      while (cursor < urls.length) {
        final url = urls[cursor++];
        try {
          await DefaultCacheManager().downloadFile(url);
        } catch (_) {
          // Media has a local mannequin fallback and is retried after the next
          // catalog refresh, so one unavailable asset must not stop the batch.
        }
      }
    }

    await Future.wait(List.generate(4, (_) => worker()));
  }
}
