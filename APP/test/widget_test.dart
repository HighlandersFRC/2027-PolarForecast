import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('shows the Polar Forecast home page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Polar Forecast'), findsOneWidget);
    expect(find.text('Home Page'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
