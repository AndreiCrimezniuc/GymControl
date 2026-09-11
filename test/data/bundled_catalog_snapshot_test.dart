import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/data/local/bundled_catalog_snapshot.dart';

void main() {
  test('offline starter catalog keeps detailed paired exercise media', () {
    expect(bundledCatalogSnapshot, isNotEmpty);

    for (final exercise in bundledCatalogSnapshot) {
      final first = exercise['image_url'] as String;
      final second = exercise['image_url2'] as String;

      expect(first, startsWith('/api/v1/exercise-images/'));
      expect(second, startsWith('/api/v1/exercise-images/'));
      expect(first, endsWith('-relaxation.png'));
      expect(second, endsWith('-tension.png'));
    }
  });
}
