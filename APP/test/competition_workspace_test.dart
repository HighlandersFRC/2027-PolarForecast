import 'package:app/models/team_stat.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:app/widgets/team_comparison.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

const teams = [
  TeamStat(Team: 101, Rank: 2, OPR: 40, Auto: 12, Teleop: 28),
  TeamStat(
      Team: 202,
      Rank: 1,
      OPR: 80,
      Auto: 22,
      Teleop: 58,
      ScoutEntries: 2,
      ScoutedMatches: 2,
      DefenseRate: 0.5),
];

void main() {
  testWidgets(
      'comparison keeps Syncfusion and distinguishes unobserved from zero',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        home: const Scaffold(
          body: TeamComparison(teams: teams, scouting: true),
        )));
    await tester.pumpAndSettle();
    expect(find.byType(SfDataGrid), findsOneWidget);
    final source = tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source;
    final death =
        source.rows.firstWhere((r) => r.getCells().first.value == 'Death rate');
    expect(death.getCells()[1].value, '—');
    expect(death.getCells()[2].value, '0%');
    expect(tester.takeException(), isNull);
  });

  testWidgets('public comparison omits group reliability data', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: const Scaffold(
            body: TeamComparison(teams: teams, scouting: false))));
    await tester.pumpAndSettle();
    final source = tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source;
    expect(source.rows.length, 5);
    expect(source.rows.any((r) => r.getCells().first.value == 'Death rate'),
        false);
  });
}
