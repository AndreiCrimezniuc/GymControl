import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/core/ui/widgets/pressable.dart';

void main() {
  testWidgets('Pressable exposes a button semantic and keyboard action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: Pressable(
            semanticLabel: 'Start workout',
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 48),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Start workout'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Start workout'));
    expect(taps, 1);
  });
}
