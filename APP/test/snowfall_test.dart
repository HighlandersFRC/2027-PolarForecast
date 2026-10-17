import 'package:app/widgets/snowfall.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('decorative flakes allow taps and respect reduced motion',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Snowfall(
          child: Scaffold(
              body: Center(
                  child: FilledButton(
        onPressed: () => taps++,
        child: const Text('Record action'),
      )))),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record action'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
