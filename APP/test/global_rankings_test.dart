import 'dart:async';
import 'dart:convert';

import 'package:app/APIService.dart';
import 'package:app/models/global_ranking.dart';
import 'package:app/services/global_rankings_controller.dart';
import 'package:app/widgets/global_rankings_board.dart';
import 'package:app/widgets/global_rankings_grid.dart';
import 'package:app/widgets/matte_theme.dart';
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
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('1000'));
      expect(selected?.eventKey, '2026cokc');
      await tester.tap(find.byKey(const ValueKey('load-more-rankings')));
      await tester.pumpAndSettle();
      expect(rankings.teams.length, 100);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      rankings.dispose();
    });
  }
}
