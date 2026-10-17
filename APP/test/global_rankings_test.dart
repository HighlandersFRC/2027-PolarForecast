import 'dart:async';
import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:app/models/global_ranking.dart';
import 'package:app/models/team_event.dart';
import 'package:app/services/global_rankings_controller.dart';
import 'package:app/widgets/global_rankings_board.dart';
import 'package:app/widgets/global_rankings_grid.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:app/widgets/team_events_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

GlobalRankingPage page(int offset,
        {String version = 'one', int total = 130, double adjustment = 0}) =>
    GlobalRankingPage(
      teams: List.generate(
          (total - offset).clamp(0, 50),
          (index) => GlobalRanking(
              rank: offset + index + 1,
              team: 1000 + offset + index,
              name: 'Polar Robotics ${offset + index}',
              opr: 250 - offset - index + adjustment,
              auto: 50 - (offset + index) / 5,
              teleop: 200 - offset - index + adjustment,
              eventKey: '2026cokc',
              eventName: 'KCMT Regional',
              eventDate: '2026-03-28')),
      year: 2026,
      total: total,
      matched: total,
      nextOffset: offset + 50 < total ? offset + 50 : null,
      snapshot: version,
      updatedAt: DateTime.utc(2026, 10, 14),
      ranges: {
        'rank': RankingMetricRange(1, total.toDouble()),
        'opr': const RankingMetricRange(0, 300),
        'auto': const RankingMetricRange(0, 100),
        'teleop': const RankingMetricRange(0, 250),
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('API requests only 50 rows and carries the search and snapshot',
      () async {
    late http.Request request;
    final api = APIService(client: MockClient((incoming) async {
      request = incoming;
      return http.Response(
          jsonEncode({
            'data': [
              {
                'rank': 80,
                'team': 4499,
                'name': 'Highlander Robotics',
                'opr': 228.922094,
                'auto': 25.946868,
                'teleop': 203.765771,
                'event_key': '2026cokc',
                'event_name': 'KCMT Regional',
                'event_date': '2026-03-28'
              }
            ],
            'year': 2026,
            'total': 3000,
            'matched': 1,
            'next_offset': null,
            'snapshot': 'one',
            'updated_at': '2026-10-14T00:00:00Z',
            'ranges': {
              'auto': {'min': -5, 'max': 100}
            },
          }),
          200);
    }));
    addTearDown(api.dispose);
    final result = await api.fetchGlobalRankings(
        offset: 50, query: ' 4499 ', snapshot: 'one');
    expect(request.url.path, '/rankings/global');
    expect(request.url.queryParameters,
        {'offset': '50', 'limit': '50', 'q': '4499', 'snapshot': 'one'});
    expect(result.teams.single.opr, 228.922094);
    expect(result.teams.single.auto, 25.946868);
    expect(result.teams.single.teleop, 203.765771);
    expect(result.ranges['auto']?.min, -5);
    expect(result.teams.single.name, 'Highlander Robotics');
  });

  testWidgets(
      'initial load is 50; load more and periodic refresh preserve loaded depth',
      (tester) async {
    final calls = <(int, String?)>[];
    var adjustment = 0.0;
    var identities = 0;
    final rankings = GlobalRankingsController(
      load: ({required offset, required query, snapshot}) async {
        calls.add((offset, snapshot));
        return page(offset, adjustment: adjustment);
      },
      identity: (_) async {
        identities++;
        return {};
      },
    );
    await tester.pump();
    expect(rankings.teams.length, 50);
    expect(calls, [(0, null)]);
    expect(identities, 0);
    await rankings.loadMore();
    expect(rankings.teams.length, 100);
    expect(calls.last, (50, 'one'));
    adjustment = 20;
    await tester.pump(const Duration(minutes: 5));
    expect(rankings.teams.length, 100);
    expect(rankings.teams.first.opr, 270);
    expect(calls.skip(2), [(0, null), (50, 'one')]);
    rankings.dispose();
  });

  testWidgets('refresh waits five minutes after the last request completes',
      (tester) async {
    final first = Completer<GlobalRankingPage>();
    var calls = 0;
    final rankings = GlobalRankingsController(
      load: ({required offset, required query, snapshot}) {
        calls++;
        return calls == 1 ? first.future : Future.value(page(0));
      },
      identity: (_) async => {},
    );
    await tester.pump(const Duration(seconds: 10));
    first.complete(page(0));
    await tester.pump();
    await tester.pump(const Duration(minutes: 4, seconds: 50));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
    rankings.dispose();
  });

  testWidgets(
      'search discards a delayed load-more response for the previous query',
      (tester) async {
    final old = Completer<GlobalRankingPage>();
    final queries = <String>[];
    final rankings = GlobalRankingsController(
      load: ({required offset, required query, snapshot}) {
        queries.add(query);
        return offset == 50
            ? old.future
            : Future.value(page(query.isEmpty ? 0 : 90));
      },
      identity: (_) async => {},
    );
    await tester.pump();
    rankings.loadMore();
    rankings.search('Polar');
    rankings.search('Polar Robotics');
    await tester.pump(const Duration(milliseconds: 350));
    expect(queries.last, 'Polar Robotics');
    expect(queries.where((query) => query == 'Polar'), isEmpty);
    expect(rankings.teams.first.rank, 91);
    old.complete(page(50));
    await tester.pump();
    expect(rankings.teams.first.rank, 91);
    expect(rankings.teams.length, 40);
    rankings.dispose();
  });

  testWidgets(
      'expired pagination restarts a consistent snapshot and still loads the next 50',
      (tester) async {
    var expired = true;
    final rankings = GlobalRankingsController(
      load: ({required offset, required query, snapshot}) async {
        if (offset == 50 && expired) {
          expired = false;
          throw RankingSnapshotExpired();
        }
        return page(offset, version: expired ? 'old' : 'fresh');
      },
      identity: (_) async => {},
    );
    await tester.pump();
    await rankings.loadMore();
    expect(rankings.teams.length, 100);
    expect(rankings.snapshot, 'fresh');
    expect(rankings.loadingMore, isFalse);
    expect(rankings.error, isNull);
    rankings.dispose();
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets(
        'rankings fit $width px and request icons only for visible teams',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final icons = <int>[];
      GlobalRanking? selected;
      final rankings = GlobalRankingsController(
        load: ({required offset, required query, snapshot}) async =>
            page(offset),
        identity: (team) async {
          icons.add(team);
          return {'avatar': 'bad base64!'};
        },
      );
      await tester.pumpWidget(MaterialApp(
          theme: buildMatteTheme(),
          home: Scaffold(
              body: GlobalRankingsBoard(
                  controller: rankings,
                  onTeamTap: (team) => selected = team))));
      await tester.pumpAndSettle();
      expect(find.text('Global rankings'), findsNothing);
      expect(find.text('POLAR FORECAST'), findsNothing);
      expect(find.textContaining('season'), findsNothing);
      expect(find.textContaining('Updated'), findsNothing);
      expect(find.textContaining('ranked teams'), findsNothing);
      expect(find.textContaining('Refreshes every'), findsNothing);
      expect(find.byType(SfDataGrid), findsOneWidget);
      expect(tester.getSize(find.byType(GlobalRankingsGrid)).width, width);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('Polar Robotics 0'), findsOneWidget);
      expect(icons.length, inInclusiveRange(1, 49));
      expect(rankings.teams.length, 50);
      final loadMore = find.byKey(const ValueKey('load-more-rankings'));
      expect(loadMore.hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('1000'));
      expect(selected?.eventKey, '2026cokc');
      final verticalScroll = find.byWidgetPredicate((widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down);
      await tester.scrollUntilVisible(loadMore, 600,
          scrollable: verticalScroll.first, maxScrolls: 15);
      await tester.pumpAndSettle();
      expect(tester.getSize(loadMore).width, closeTo(width, 2));
      await tester.tap(loadMore);
      await tester.pumpAndSettle();
      expect(rankings.teams.length, 100);
      expect(loadMore.hitTestable(), findsNothing);
      await tester.scrollUntilVisible(loadMore, 600,
          scrollable: verticalScroll.first, maxScrolls: 15);
      await tester.tap(loadMore);
      await tester.pumpAndSettle();
      expect(rankings.teams.length, 130);
      expect(loadMore, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      rankings.dispose();
    });
  }

  test('API loads REBUILT event history with dates and locations',
      () async {
    final api = APIService(client: MockClient((request) async {
      expect(request.url.path, '/teams/1000/events');
      expect(request.url.queryParameters, isEmpty);
      return http.Response(
          jsonEncode({
            'team': 1000,
            'data': [
              {
                'key': '2026early',
                'name': 'Earlier Regional',
                'start_date': '2026-03-01',
                'end_date': '2026-03-03',
                'city': 'Denver',
                'state_prov': 'CO',
                'country': 'USA',
              },
              {'key': '2026new', 'name': 'Latest Regional'},
            ],
          }),
          200);
    }));
    addTearDown(api.dispose);
    final events = await api.fetchTeamEvents(1000);
    expect(events.map((event) => event.key), ['2026early', '2026new']);
    expect(events.first.start, DateTime(2026, 3, 1));
    expect(events.first.end, DateTime(2026, 3, 3));
    expect(events.first.location, 'Denver, CO, USA');
    expect(events.last.start, isNull);
  });

  for (final width in [320.0, 1200.0]) {
    testWidgets('team popup fits $width px and opens the selected event',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rankings = GlobalRankingsController(
        load: ({required offset, required query, snapshot}) async =>
            page(offset),
        identity: (_) async => {},
      );
      final history = Completer<List<TeamEvent>>();
      String? destination;
      await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        onGenerateRoute: (settings) {
          destination = settings.name;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Selected event page')),
          );
        },
        home: Scaffold(
            body: GlobalRankingsBoard(
          controller: rankings,
          loadTeamEvents: (team) {
            expect(team, 1000);
            return history.future;
          },
        )),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1000'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TeamEventsDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(destination, isNull);
      history.complete([
        TeamEvent(
            key: '2026new',
            name: 'Latest Regional',
            start: DateTime(2026, 4, 1)),
        TeamEvent(
            key: '2026early',
            name: 'Earlier Regional',
            start: DateTime(2026, 3, 1)),
      ]);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Earlier Regional')).dy,
          greaterThan(tester.getTopLeft(find.text('Latest Regional')).dy));
      expect(find.text('2026 REBUILT \u00b7 Newest to oldest'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Earlier Regional'));
      await tester.pumpAndSettle();
      expect(destination, '/event/2026early');
      expect(find.byType(TeamEventsDialog), findsNothing);
      expect(find.text('Selected event page'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      rankings.dispose();
    });
  }

  testWidgets(
      'event history can retry a failed request and dismiss an empty history',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      theme: buildMatteTheme(),
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (_) => TeamEventsDialog(
                    team: page(0).teams.first,
                    load: () async {
                      if (++calls == 1) throw Exception('Offline');
                      return [];
                    },
                  ),
                ),
                child: const Text('Open history'),
              ))),
    ));
    await tester.tap(find.text('Open history'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load event history.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No event history found.'), findsOneWidget);
    expect(calls, 2);
    await tester.tap(find.byTooltip('Close event history'));
    await tester.pumpAndSettle();
    expect(find.byType(TeamEventsDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
