import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/subscription/pro_status.dart';

void main() {
  test('ProStatus parses the derived flag and expiration', () {
    final status = ProStatus.fromJson({
      'is_pro': true,
      'expires_at': '2027-07-29T12:00:00Z',
    });

    expect(status.isPro, isTrue);
    expect(status.expiresAt, DateTime.utc(2027, 7, 29, 12));
  });

  test('ProStatus tolerates a missing expiration', () {
    final status = ProStatus.fromJson({'is_pro': false});

    expect(status.isPro, isFalse);
    expect(status.expiresAt, isNull);
  });
}
