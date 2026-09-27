import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/main.dart';
import 'package:app/services/auth_service.dart';

void main() {
  testWidgets('shows the Polar Forecast home page',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(),
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Polar Forecast'), findsOneWidget);
    expect(find.text('Look up any team'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
