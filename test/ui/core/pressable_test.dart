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

  testWidgets('Pressable removes scale animation when Reduce Motion is on', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
        home: Center(
          child: Pressable(
            onTap: () {},
            child: const SizedBox(width: 100, height: 48),
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
  });
}
