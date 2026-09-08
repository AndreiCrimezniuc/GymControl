import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/data/sync/sync_service.dart';

void main() {
  test('transient client statuses remain retryable', () {
    for (final status in [401, 408, 409, 423, 425, 429]) {
      final outcome = syncOutcomeForStatus(status, success: 204);
      expect(outcome.success, isFalse, reason: '$status must not be lost');
      expect(outcome.permanent, isFalse, reason: '$status must retry');
    }
  });

  test('validation failures become recoverable dead letters', () {
    for (final status in [400, 403, 404, 410, 413, 422]) {
      final outcome = syncOutcomeForStatus(status, success: 204);
      expect(outcome.success, isFalse);
      expect(outcome.permanent, isTrue, reason: '$status is permanent');
    }
  });

  test('server failures and successful responses have explicit outcomes', () {
    expect(syncOutcomeForStatus(503, success: 204).permanent, isFalse);
    expect(syncOutcomeForStatus(204, success: 204).success, isTrue);
  });
}
