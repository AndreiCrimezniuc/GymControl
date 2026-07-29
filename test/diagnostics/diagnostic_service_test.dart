import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:gymboss/data/diagnostics/diagnostic_service.dart';

void main() {
  late Directory temp;
  late Box<String> box;

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('gymboss-diagnostics-test-');
    Hive.init(temp.path);
    box = await Hive.openBox<String>('diagnostic-test');
    await DiagnosticService.instance.init(
      box: box,
      appVersion: '1.0.0',
      buildNumber: '1',
    );
  });

  tearDown(() => box.clear());

  tearDownAll(() async {
    await box.close();
    await temp.delete(recursive: true);
  });

  test('sanitizer keeps allowlisted technical values only', () {
    final safe = DiagnosticService.sanitizeAttributes({
      'status_code': 503,
      'operation': 'load_workouts',
      'email': 'person@example.com',
      'message': 'free-form content',
      'error_code': 'person@example.com',
    });

    expect(safe, {'status_code': 503, 'operation': 'load_workouts'});
  });

  test('sanitizer rejects token-like values', () {
    expect(
      DiagnosticService.sanitizeAttributes({
        'operation': 'Bearer secret',
        'error_code': 'eyJheader.payload.signature',
      }),
      isEmpty,
    );
  });

  test('local buffer is capped at 200 events', () async {
    for (var i = 0; i < 205; i++) {
      await DiagnosticService.instance.record(
        'test.event',
        attributes: {'queue_size': i},
      );
    }

    expect(DiagnosticService.instance.eventCount, 200);
  });
}
