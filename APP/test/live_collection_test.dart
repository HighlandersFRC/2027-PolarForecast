import 'package:app/models/auto_route.dart';
import 'package:app/models/scouting_capture.dart';
import 'package:app/widgets/fuel_burst_pad.dart';
import 'package:app/widgets/live_collection_page.dart';
import 'package:app/widgets/matte_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 850),
    const Size(390, 850),
    const Size(844, 390)
  ]) {
    testWidgets('live field recording, count dragging and undo fit $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime.utc(2026);
      final capture = ScoutingCapture(clock: () => now);
      await tester.pumpWidget(MaterialApp(
          theme: buildMatteTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => LiveCollectionPage(
                                  capture: capture,
                                  team: 123,
                                  match: '4',
                                  blue: true))),
                      child: const Text('Open recorder'))))));
      await tester.tap(find.text('Open recorder'));
      await tester.pumpAndSettle();
      final preload = find.byKey(const ValueKey('field-action-Preload Left'));
      await tester.ensureVisible(preload);
      await tester.tap(preload);
      await tester.pump();
      await tester
          .ensureVisible(find.byKey(const ValueKey('start-live-match')));
      await tester.tap(find.byKey(const ValueKey('start-live-match')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final crossing =
          find.byKey(ValueKey('field-action-${AutoRoute.crossings.first}'));
      await tester.ensureVisible(crossing);
      await tester.tap(crossing);
      await tester.pumpAndSettle();
      expect(capture.neutralZone, isTrue);
      expect(find.byType(FuelBurstPad), findsNothing);
      final intake =
          find.byKey(const ValueKey('field-action-${AutoRoute.neutral}'));
      await tester.ensureVisible(intake);
      await tester.tap(intake);
      await tester.pump();
      await tester.ensureVisible(crossing);
      await tester.tap(crossing);
      await tester.pumpAndSettle();
      expect(capture.neutralZone, isFalse);
      await tester.ensureVisible(find.text('Count'));
      await tester.tap(find.text('Count'));
      await tester.pumpAndSettle();
      final pad = find.byType(FuelBurstPad);
      await tester.ensureVisible(pad);
      final scroll =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      final offset = scroll.pixels;
      final gesture = await tester.startGesture(tester.getCenter(pad));
      await gesture.moveBy(const Offset(0, -50));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scroll.pixels, offset,
          reason: 'Dragging the counter must not scroll the page');
      await gesture.moveBy(const Offset(0, 20));
      await gesture.up();
      await tester.pump();
      expect(capture.fuel(CapturePhase.auto), 4);
      expect(capture.autoPath.last, AutoRoute.shot);
      await tester.tap(find.byTooltip('Undo last observation'));
      await tester.pump();
      expect(capture.fuel(CapturePhase.auto), 0);
      now = now.add(const Duration(seconds: 23));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HoldDefensePad), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      capture.dispose();
    });
  }

  testWidgets('a held auto burst commits once when the scoring delay begins',
      (tester) async {
    var now = DateTime.utc(2026);
    final capture = ScoutingCapture(clock: () => now)
      ..route('Preload Center')
      ..start();
    await tester.pumpWidget(MaterialApp(
        theme: buildMatteTheme(),
        home: LiveCollectionPage(
            capture: capture, team: 123, match: '1', blue: false)));
    final pad = find.byType(FuelBurstPad);
    await tester.ensureVisible(pad);
    final gesture = await tester.startGesture(tester.getCenter(pad));
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pump();
    expect(capture.phase, CapturePhase.delay);
    expect(capture.fuel(CapturePhase.auto), 1);
    expect(
        capture.actions.where((a) => a.kind == CaptureKind.shooting).length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    capture.dispose();
  });

  testWidgets('pointer cancellation discards an unfinished burst',
      (tester) async {
    var commits = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FuelBurstPad(
                mode: FuelCountingMode.count,
                phase: CapturePhase.teleop,
                elapsedMs: () => 30000,
                onCommit: (_, __, ___, ____) => commits++))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(FuelBurstPad)));
    await gesture.moveBy(const Offset(70, 0));
    await gesture.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(commits, 0);
  });

  testWidgets('rate mode accumulates fuel over hold time and records duration',
      (tester) async {
    int? count;
    int? duration;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FuelBurstPad(
                mode: FuelCountingMode.rate,
                phase: CapturePhase.teleop,
                elapsedMs: () => 30000,
                onCommit: (n, ms, _, __) {
                  count = n;
                  duration = ms;
                }))));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(FuelBurstPad)));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    expect(count, greaterThanOrEqualTo(2));
    expect(duration, greaterThanOrEqualTo(500));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
