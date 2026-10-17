@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/main.dart';
import 'package:app/APIService.dart';
import 'package:app/models/team_stat.dart';
import 'package:app/models/match_prediction.dart';
import 'package:app/pages/event_page.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/widgets/MatchScouting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EventApi extends APIService {
  @override
  Future<String> fetchEventDisplayNameByKey(String event) async =>
      'Colorado Regional';
  @override
  Future<List<TeamStat>> fetchRawStatsByEvent(String event,
          {String? username}) async =>
      const [TeamStat(Team: 101, Rank: 1, OPR: 80)];
  @override
  Future<List<MatchPrediction>> fetchPredictionsByEvent(String event) async =>
      [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
    expect(find.text('Global rankings'), findsNothing);
    expect(find.text('Find your event'), findsNothing);
    expect(find.byKey(const ValueKey('ranking-search')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final width in [320.0, 1280.0]) {
    testWidgets('home fits $width px', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(), child: const MyApp()));
      await tester.pump();
      expect(find.text('Find your event'), findsNothing);
      expect(find.byKey(const ValueKey('ranking-search')), findsOneWidget);
      expect(find.byTooltip('Search events'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'phone navigation preserves the scouting draft between event sections',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
          home: EventPage(eventCode: '2026code', apiService: _EventApi())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Team stats'), findsOneWidget);
    expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .length,
        5);
    await tester.tap(find.text('Scout'));
    await tester.pumpAndSettle();
    final form = tester.state(find.byType(MatchScouting));
    await tester.tap(find.text('4  Review'));
    await tester.pumpAndSettle();
    final comments = find.widgetWithText(TextFormField, 'Comments');
    await tester.ensureVisible(comments);
    await tester.enterText(comments, 'Strong defense on the far side');
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scout'));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(MatchScouting)), same(form));
    expect(find.text('Strong defense on the far side'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
