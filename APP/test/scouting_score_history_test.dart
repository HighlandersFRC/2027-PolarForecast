import 'package:app/models/scouted_match_score.dart';
import 'package:app/widgets/scouting_score_history.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> report(Object match,
        {Object? auto = 5,
        Object? teleop = 10,
        String event = '2026test',
        String group = 'group-1',
        int team = 101}) =>
    {
      'event': event,
      'groupId': group,
      'team': team,
      'match': match,
      'data': {
        'autoScouting': {'fuel_scored': auto},
        'teleopScouting': {'fuel_scored': teleop},
      },
    };

List<ScoutedMatchScore> scores(List<Map<String, dynamic>> entries) =>
    ScoutedMatchScore.fromEntries(entries,
        event: '2026test', team: 101, groupId: 'group-1');

void main() {
  test('sorts qualification and playoff reports by match, not submission order',
      () {
    final result = scores([
      report('sf2m1'),
      report('10'),
      report('2026test_qm2'),
      report('f1m1'),
      report('1'),
      report('qf1m2'),
    ]);
    expect(result.map((score) => score.label),
        ['QM1', 'QM2', 'QM10', 'QF1-2', 'SF2-1', 'F1-1']);
    expect(result.map((score) => score.totalFuel), everyElement(15));
  });

  test('combines reports of the same match without double-counting robot fuel',
      () {
    final result = scores([
      report(1, auto: 0, teleop: 0),
      report('2026test_qm1', auto: 10, teleop: 20),
    ]).single;
    expect(result.reports, 2);
    expect(result.autoFuel, 5);
    expect(result.teleopFuel, 10);
    expect(result.totalFuel, 15);
  });

  test('plots measured zero, omits incomplete, invalid, and unscouted matches',
      () {
    final result = scores([
      report('1', auto: 0, teleop: 0),
      report('2', auto: null),
      report('3', teleop: null),
      report('4', auto: 301),
      report('5', teleop: 1001),
      report('6', auto: -1),
      report('7', auto: double.nan),
      report('8', auto: true),
      report('unknown'),
    ]);
    expect(result, hasLength(1));
    expect(result.single.label, 'QM1');
    expect(result.single.totalFuel, 0);
  });

  test(
      'only uses this group, event, and team; TBA scores and OPR never enter history',
      () {
    final tba = {
      'key': '2026test_qm2',
      'event': '2026test',
      'groupId': 'group-1',
      'team': 101,
      'match': '2',
      'alliances': {
        'red': {'score': 900}
      },
      'score_breakdown': {
        'red': {'totalPoints': 999}
      },
      'OPR': 5000,
      'totalOPR': 6000,
    };
    final result = scores([
      report('1'),
      tba,
      report('3', group: 'another-group'),
      report('4', team: 202),
      report('5', event: '2026other'),
      report('2026other_qm6'),
    ]);
    expect(result, hasLength(1));
    expect(result.single.totalFuel, 15);
    expect(
        ScoutedMatchScore.fromEntries([report('1')],
            event: '2026test', team: 101, groupId: ''),
        isEmpty);
  });

  testWidgets(
      'mobile graph plots individual scouted matches with auto, teleop, and total',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
          body: SingleChildScrollView(
              child: ScoutingScoreHistory(
        entries: [
          report('1', auto: 0, teleop: 0),
          report('3', auto: 10, teleop: 20)
        ],
        event: '2026test',
        team: 101,
        groupId: 'group-1',
      ))),
    ));
    await tester.pumpAndSettle();
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData, hasLength(3));
    expect(chart.data.lineBarsData[0].spots.map((point) => point.y), [0, 30]);
    expect(chart.data.lineBarsData[1].spots.map((point) => point.y), [0, 10]);
    expect(chart.data.lineBarsData[2].spots.map((point) => point.y), [0, 20]);
    expect(find.text('QM2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty scouting displays an empty state, not a TBA history chart',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: ScoutingScoreHistory(
          entries: [], event: '2026test', team: 101, groupId: 'group-1'),
    )));
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('No complete scouting scores yet.'), findsOneWidget);
  });
}
