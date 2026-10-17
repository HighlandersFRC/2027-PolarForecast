import 'package:app/models/auto_route.dart';
import 'package:app/widgets/auto_path_recorder.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder action(String value) => find.byKey(ValueKey('route-action-$value'));

void main() {
  test('route rules preserve crossing prerequisites and API action names', () {
    expect(AutoRoute.validate([]), isNull);
    expect(AutoRoute.validate([AutoRoute.neutral]), isNotNull);
    expect(AutoRoute.validate(['Preload Left', AutoRoute.neutral]), isNotNull);
    expect(
        AutoRoute.validate([
          'Preload Left',
          'Went Under Left Trench',
          AutoRoute.neutral,
          AutoRoute.shot,
          'Went Over Right Bump',
          AutoRoute.depot
        ]),
        isNull);
    expect(
        AutoRoute.validate([
          'Preload Left',
          'Went Under Left Trench',
          AutoRoute.neutral,
          AutoRoute.depot
        ]),
        isNotNull);
    expect(AutoRoute.validate(['Preload Left', 'Preload Right']), isNotNull);
    expect(AutoRoute.validate(['Start Center', AutoRoute.shot, AutoRoute.shot]),
        isNull);
    expect(AutoRoute.validate(['Preload Left', 'invented action']), isNotNull);
  });

  for (final width in [320.0, 390.0, 1100.0]) {
    testWidgets('large controls fit $width px and support undo and redo',
        (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var path = <String>[];
      await tester.pumpWidget(MaterialApp(
          theme: buildMatteTheme(),
          home: Scaffold(
            body: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 850),
                    textScaler: const TextScaler.linear(1.3)),
                child: StatefulBuilder(
                    builder: (_, setState) => SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: AutoPathRecorder(
                              path: path,
                              onChanged: (value) =>
                                  setState(() => path = value)),
                        ))),
          )));
      expect(tester.takeException(), isNull);
      expect(tester.widget<FilledButton>(action(AutoRoute.neutral)).onPressed,
          isNull);
      for (final step in [
        'Preload Left',
        'Went Under Left Trench',
        AutoRoute.neutral,
        AutoRoute.shot
      ]) {
        await tester.ensureVisible(action(step));
        await tester.tap(action(step));
        await tester.pumpAndSettle();
      }
      expect(path, [
        'Preload Left',
        'Went Under Left Trench',
        AutoRoute.neutral,
        AutoRoute.shot
      ]);
      await tester.ensureVisible(find.byKey(const ValueKey('route-undo')));
      await tester.tap(find.byKey(const ValueKey('route-undo')));
      await tester.pumpAndSettle();
      expect(path.last, AutoRoute.neutral);
      await tester.tap(find.byKey(const ValueKey('route-redo')));
      await tester.pumpAndSettle();
      expect(path.last, AutoRoute.shot);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('stand mode updates the parent draft and counts fuel separately',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var path = <String>[];
    var fuel = 0;
    await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        home: Scaffold(
          body: StatefulBuilder(
              builder: (_, setState) => SingleChildScrollView(
                    child: AutoPathRecorder(
                        path: path,
                        fuel: fuel,
                        onChanged: (value) => setState(() => path = value),
                        onFuelChanged: (value) => setState(() => fuel = value)),
                  )),
        )));
    await tester.tap(find.byKey(const ValueKey('route-focus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('route-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('route-field-image')), findsOneWidget);
    await tester.ensureVisible(action('Preload Center'));
    await tester.tap(action('Preload Center'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(action(AutoRoute.shot));
    await tester.tap(action(AutoRoute.shot));
    await tester.pumpAndSettle();
    expect(path, ['Preload Center', AutoRoute.shot]);
    expect(fuel, 0);
    await tester.tap(find.text('+5'));
    await tester.pumpAndSettle();
    expect(fuel, 5);
    await tester.tap(find.text('Done · 2 recorded actions'));
    await tester.pumpAndSettle();
    expect(find.text('Auto recording'), findsNothing);
    expect(path.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rewinding a route removes the dependent suffix and remains undoable',
      (tester) async {
    var path = [
      'Preload Right',
      'Went Under Right Trench',
      AutoRoute.neutral,
      AutoRoute.shot
    ];
    await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        home: Scaffold(
          body: StatefulBuilder(
              builder: (_, setState) => SingleChildScrollView(
                  child: AutoPathRecorder(
                      path: path,
                      onChanged: (value) => setState(() => path = value)))),
        )));
    await tester.tap(find.text('Edit steps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neutral intake').last);
    await tester.pumpAndSettle();
    expect(path, ['Preload Right', 'Went Under Right Trench']);
    expect(AutoRoute.validate(path), isNull);
    await tester.tap(find.byKey(const ValueKey('route-undo')));
    await tester.pumpAndSettle();
    expect(path, [
      'Preload Right',
      'Went Under Right Trench',
      AutoRoute.neutral,
      AutoRoute.shot
    ]);
  });

  testWidgets('starting a different robot clears the previous route history',
      (tester) async {
    var path = <String>[];
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        home: Scaffold(
          body: StatefulBuilder(builder: (_, setState) {
            update = setState;
            return SingleChildScrollView(
                child: AutoPathRecorder(
                    path: path,
                    onChanged: (value) => setState(() => path = value)));
          }),
        )));
    await tester.ensureVisible(action('Preload Left'));
    await tester.tap(action('Preload Left'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('route-undo')));
    await tester.tap(find.byKey(const ValueKey('route-undo')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('route-redo')))
            .onPressed,
        isNotNull);
    // Changing the robot starts a fresh external draft.
    update(() => path = ['Preload Right']);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('route-redo')))
            .onPressed,
        isNull);
  });
}
