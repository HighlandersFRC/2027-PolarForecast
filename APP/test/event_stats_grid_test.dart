import 'package:app/models/team_stat.dart';
import 'package:app/widgets/event_stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

const teams = [
  TeamStat(
      Team: 101,
      Rank: 2,
      OPR: -12.5,
      Auto: 1,
      Teleop: 2,
      Tower: 3,
      ScoutEntries: 2,
      ScoutedMatches: 2,
      DeathRate: 1,
      DefenseRate: 0),
  TeamStat(
      Team: 202,
      Rank: 1,
      OPR: 90,
      Auto: 10,
      Teleop: 20,
      Tower: 30,
      ScoutEntries: 4,
      ScoutedMatches: 4,
      DeathRate: 0,
      DefenseRate: 1),
];

Finder cell(int team, String metric) =>
    find.byKey(ValueKey('stats-cell-$team-$metric'));

Color? color(WidgetTester tester, int team, String metric) =>
    tester.widget<Container>(cell(team, metric)).color;

Future<void> mount(
  WidgetTester tester, {
  double width = 320,
  List<TeamStat> visible = teams,
  bool scouting = false,
  ValueChanged<String>? onSort,
  ValueChanged<TeamStat>? onTeamTap,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(12),
      child: EventStatsGrid(
        teams: visible,
        eventTeams: teams,
        showScoutingAnalysis: scouting,
        sortKey: 'rank',
        ascending: true,
        onSort: onSort ?? (_) {},
        onTeamTap: onTeamTap ?? (_) {},
      ),
    )),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'phone uses the real grid with heatmapped cells and a frozen team column',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    expect(find.byType(SfDataGrid), findsOneWidget);
    expect(
        tester.widget<SfDataGrid>(find.byType(SfDataGrid)).frozenColumnsCount,
        1);
    expect(color(tester, 101, 'opr'), isNot(color(tester, 202, 'opr')));
    // A lower rank uses the same favorable end of the scale as a higher OPR.
    expect(color(tester, 202, 'rank'), color(tester, 202, 'opr'));
    final frozenPosition = tester.getTopLeft(cell(101, 'team'));
    await tester.dragFrom(
        tester.getCenter(cell(101, 'opr')), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(cell(101, 'tower').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(cell(101, 'team')), frozenPosition);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'filtering and resizing keep the event heat scale and data source',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, width: 1200);
    final source = tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source;
    final originalColor = color(tester, 101, 'opr');
    await mount(tester, visible: [teams.first]);
    expect(tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source,
        same(source));
    expect(color(tester, 101, 'opr'), originalColor);
    expect(find.text('-12.5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'headers sort and team taps use the current row order after refresh',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? sorted;
    TeamStat? selected;
    await mount(tester, onSort: (key) => sorted = key);
    await tester.tap(find.text('OPR'));
    expect(sorted, 'opr');
    await mount(tester,
        visible: teams.reversed.toList(), onTeamTap: (team) => selected = team);
    await tester.tap(cell(202, 'team'));
    expect(selected?.Team, 202);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'scouting columns follow the session and missing observations stay neutral',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, width: 1200, scouting: true);
    expect(find.text('Death %'), findsOneWidget);
    expect(color(tester, 202, 'death'), color(tester, 202, 'opr'));
    final noScouting = teams.last.copyWith(ScoutEntries: 0);
    await mount(tester, width: 1200, scouting: true, visible: [noScouting]);
    expect(color(tester, 202, 'death'), EventStatsGrid.surfaceColor);
    await mount(tester, width: 1200);
    final columns = tester.widget<SfDataGrid>(find.byType(SfDataGrid)).columns;
    expect(
        columns.map((column) => column.columnName), isNot(contains('death')));
    expect(
        columns
            .map((column) => column.columnName)
            .any((name) => name.contains('Average')),
        isFalse);
    expect(tester.takeException(), isNull);
  });
}
