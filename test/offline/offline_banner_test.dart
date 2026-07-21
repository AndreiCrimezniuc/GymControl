import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gymboss/data/sync/sync_service.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/offline_banner.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
  create: (_) => ThemeController(),
  child: CupertinoApp(home: child),
);

void main() {
  tearDown(() {
    // reset to healthy state between tests
    SyncService.instance.status.value = const SyncStatus(
      online: true,
      pending: 0,
    );
  });

  testWidgets('hidden when online and synced', (tester) async {
    SyncService.instance.status.value = const SyncStatus(
      online: true,
      pending: 0,
    );
    await tester.pumpWidget(_wrap(const OfflineBanner()));
    expect(find.byType(SizedBox), findsOneWidget); // renders SizedBox.shrink
    expect(find.textContaining('Offline'), findsNothing);
    expect(find.textContaining('Syncing'), findsNothing);
  });

  testWidgets('shows offline + pending count', (tester) async {
    SyncService.instance.status.value = const SyncStatus(
      online: false,
      pending: 3,
    );
    await tester.pumpWidget(_wrap(const OfflineBanner()));
    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.textContaining('3 changes'), findsOneWidget);
  });

  testWidgets('shows syncing when online with pending', (tester) async {
    SyncService.instance.status.value = const SyncStatus(
      online: true,
      pending: 1,
    );
    await tester.pumpWidget(_wrap(const OfflineBanner()));
    expect(find.textContaining('Syncing 1 change'), findsOneWidget);
  });

  test('SyncStatus equality avoids redundant rebuilds', () {
    const a = SyncStatus(online: true, pending: 2);
    const b = SyncStatus(online: true, pending: 2);
    const c = SyncStatus(online: false, pending: 2);
    expect(a, equals(b));
    expect(a, isNot(equals(c)));
    expect(a.hasPending, isTrue);
  });
}
