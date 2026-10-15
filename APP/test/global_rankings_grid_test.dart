import 'package:app/models/global_ranking.dart';
import 'package:app/widgets/global_rankings_grid.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

const teams = [
  GlobalRanking(
      rank: 2,
      team: 101,
      name: 'Low scores',
      opr: 0,
      auto: 0,
      teleop: 0,
      eventKey: '2026test',
      eventName: 'Test',
      eventDate: '2026-10-01'),
  GlobalRanking(
      rank: 1,
      team: 202,
      name: 'High scores',
      opr: 100,
      auto: 10,
      teleop: 90,
      eventKey: '2026test',
      eventName: 'Test',
      eventDate: '2026-10-01'),
];
const ranges = {
  'rank': RankingMetricRange(1, 2),
  'opr': RankingMetricRange(0, 100),
  'auto': RankingMetricRange(0, 10),
  'teleop': RankingMetricRange(0, 90),
};
Finder cell(int team, String metric) =>
    find.byKey(ValueKey('ranking-cell-$team-$metric'));
Color? color(WidgetTester tester, int team, String metric) =>
    tester.widget<Container>(cell(team, metric)).color;

Future<void> mount(WidgetTester tester, double width,
    {List<GlobalRanking> visible = teams}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MaterialApp(
      theme: buildMatteTheme(),
      home: Scaffold(
        body: GlobalRankingsGrid(
            teams: visible,
            ranges: ranges,
            identity: (_) async => {},
            onTeamTap: (_) {}),
      )));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('OPR, Auto, and Teleop use the same matte heat scale on desktop',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, 1200);
    expect(find.byType(SfDataGrid), findsOneWidget);
    for (final metric in ['opr', 'auto', 'teleop']) {
      expect(color(tester, 101, metric), const Color(0xFF543C43));
      expect(color(tester, 202, metric), const Color(0xFF315A4A));
    }
    expect(color(tester, 202, 'rank'), color(tester, 202, 'opr'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'phone heatmaps stay fixed when filtered; team identity stays frozen while scrolling',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, 1200);
    final source = tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source;
    final initialColor = color(tester, 101, 'opr');
    await mount(tester, 320, visible: [teams.first]);
    expect(tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source,
        same(source));
    expect(
        tester.widget<SfDataGrid>(find.byType(SfDataGrid)).frozenColumnsCount,
        2);
    expect(color(tester, 101, 'opr'), initialColor);
    final teamPosition =
        tester.getTopLeft(find.byKey(const ValueKey('ranking-101')));
    await tester.dragFrom(
        tester.getCenter(cell(101, 'opr')), const Offset(-88, 0));
    await tester.pumpAndSettle();
    expect(cell(101, 'auto').hitTestable(), findsOneWidget);
    expect(color(tester, 101, 'auto'), initialColor);
    await tester.dragFrom(
        tester.getCenter(cell(101, 'auto')), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(cell(101, 'teleop').hitTestable(), findsOneWidget);
    expect(color(tester, 101, 'teleop'), initialColor);
    expect(tester.getTopLeft(find.byKey(const ValueKey('ranking-101'))),
        teamPosition);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing phases remain neutral instead of showing invented zero scores',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, 1200, visible: [
      const GlobalRanking(
        rank: 1,
        team: 303,
        name: 'Missing phases',
        opr: 50,
        eventKey: '2026test',
        eventName: 'Test',
        eventDate: '2026-10-01',
      )
    ]);
    expect(color(tester, 303, 'auto'), AppColors.surface);
    expect(color(tester, 303, 'teleop'), AppColors.surface);
    expect(find.text('\u2014'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
