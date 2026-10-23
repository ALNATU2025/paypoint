import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypoint/widgets/common.dart';
import 'package:paypoint/widgets/motion.dart';

// Widget tests use plain MaterialApp (no Google Fonts) so they run offline.

void main() {
  testWidgets('PrimaryButton calls onPressed once per tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: PrimaryButton(label: 'Pay', onPressed: () => taps++))),
    ));

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('Disabled PrimaryButton ignores taps', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: PrimaryButton(label: 'Pay', onPressed: null))),
    ));

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    // No exception and nothing to assert beyond the button still being there.
    expect(find.text('Pay'), findsOneWidget);
  });

  testWidgets('SlidingSegments reports the tapped index', (tester) async {
    var index = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SlidingSegments(
            labels: const ['1 month', '3 months', '6 months'],
            index: index,
            onChanged: (i) => setState(() => index = i),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('6 months'));
    await tester.pumpAndSettle();
    expect(index, 2);
  });

  testWidgets('FadeSlideIn ends fully visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FadeSlideIn(child: Text('Hello'))),
    ));
    await tester.pumpAndSettle();
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Hello'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1.0);
  });
}
