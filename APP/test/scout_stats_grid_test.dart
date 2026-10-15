import 'package:app/models/scout_stat.dart';
import 'package:app/widgets/event_stats_grid.dart';
import 'package:app/widgets/scout_stats_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

const scouts = [
  ScoutStat(
      id: 'a',
      name: 'Alex',
      username: 'alex1',
      trustRating: 65,
      contribution: 75,
      entries: 3,
      provisional: true),
  ScoutStat(
      id: 'b',
      name: 'Blair',
      username: 'blair1',
      trustRating: 82,
      contribution: 25,
      entries: 8,
      provisional: false),
  ScoutStat(
      id: 'c',
      name: 'Casey',
      username: 'casey1',
      trustRating: null,
      contribution: 0,
      entries: 0,
      provisional: true),
];

Finder cell(String id, String metric) =>
    find.byKey(ValueKey('scout-cell-$id-$metric'));

Future<void> mount(WidgetTester tester,
    {double width = 1200, List<ScoutStat> rows = scouts}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: ScoutStatsGrid(scouts: rows))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('metric headers sort and number names; unknown trust stays last',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    expect(find.text('1. Blair'), findsOneWidget);
    expect(find.text('65.0*'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await tester.tap(find.text('Trust / 100'));
    await tester.pumpAndSettle();
    expect(find.text('1. Alex'), findsOneWidget);
    expect(find.text('3. Casey'), findsOneWidget);
    await tester.tap(find.text('Contribution %'));
    await tester.pumpAndSettle();
    expect(find.text('1. Alex'), findsOneWidget);
    await tester.tap(find.text('Entries'));
    await tester.pumpAndSettle();
    expect(find.text('1. Blair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all three metrics are heatmapped and missing trust is neutral',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    for (final key in ['trust', 'contribution', 'entries']) {
      expect(tester.widget<Container>(cell('a', key)).color,
          isNot(tester.widget<Container>(cell('b', key)).color));
    }
    expect(tester.widget<Container>(cell('c', 'trust')).color,
        EventStatsGrid.surfaceColor);
  });

  testWidgets(
      'phone scrolls metrics while names stay frozen, refresh retains source',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, width: 320);
    final grid = tester.widget<SfDataGrid>(find.byType(SfDataGrid));
    expect(grid.frozenColumnsCount, 1);
    final position = tester.getTopLeft(cell('b', 'name'));
    await tester.dragFrom(
        tester.getCenter(cell('b', 'trust')), const Offset(-270, 0));
    await tester.pumpAndSettle();
    expect(cell('b', 'entries').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(cell('b', 'name')), position);
    await mount(tester, rows: scouts.reversed.toList());
    expect(tester.widget<SfDataGrid>(find.byType(SfDataGrid)).source,
        same(grid.source));
    expect(find.text('1. Blair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
