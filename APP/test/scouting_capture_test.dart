import 'dart:convert';
import 'package:app/models/auto_route.dart';
import 'package:app/models/scouting_capture.dart';
import 'package:app/models/2026Matchscouting.dart';
import 'package:app/models/scout_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late ScoutingCapture capture;
  setUp(() {
    now = DateTime.utc(2026, 1, 1);
    capture = ScoutingCapture(clock: () => now);
  });
  tearDown(() => capture.dispose());

  test('clock follows auto, scoring delay, teleop, endgame, review', () {
    expect(capture.phase, CapturePhase.setup);
    capture.start();
    expect(capture.secondsRemaining, 20);
    for (final (seconds, phase, remaining, endgame) in [
      (19, CapturePhase.auto, 1, false),
      (20, CapturePhase.delay, 3, false),
      (23, CapturePhase.teleop, 140, false),
      (133, CapturePhase.teleop, 30, true),
      (163, CapturePhase.review, 0, false),
    ]) {
      now = DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds));
      capture.tick();
      expect(capture.phase, phase);
      expect(capture.secondsRemaining, remaining);
      expect(capture.endgame, endgame);
    }
    capture.syncClock(30);
    expect(capture.phase, CapturePhase.teleop);
    expect(capture.secondsRemaining, 133);
    capture.finish();
    now = now.add(const Duration(minutes: 10));
    expect(capture.elapsedMs, 30000);
  });

  test('crossing parity allows the same lane out and back', () {
    expect(capture.route(AutoRoute.neutral), isNotNull);
    expect(capture.route('Preload Left'), isNull);
    expect(capture.route(AutoRoute.crossings.first), isNull);
    expect(capture.neutralZone, isTrue);
    expect(capture.route(AutoRoute.neutral), isNull);
    expect(capture.route(AutoRoute.depot), isNotNull);
    expect(capture.route(AutoRoute.crossings.first), isNull);
    expect(capture.neutralZone, isFalse);
    expect(capture.route(AutoRoute.depot), isNull);
    expect(AutoRoute.validate(capture.autoPath), isNull);
  });

  test('a shooting burst and its route shot undo and redo as one observation',
      () {
    capture.route('Preload Center');
    capture.start();
    expect(
        capture.score(
            quantity: 12,
            phase: CapturePhase.auto,
            startMs: 1000,
            durationMs: 2000),
        isTrue);
    expect(capture.autoPath, ['Preload Center', AutoRoute.shot]);
    expect(capture.fuel(CapturePhase.auto), 12);
    capture.undo();
    expect(capture.autoPath, ['Preload Center']);
    expect(capture.fuel(CapturePhase.auto), 0);
    capture.redo();
    expect(capture.fuel(CapturePhase.auto), 12);
    expect(capture.actions.last.durationMs, 2000);
    capture.correctFuel(CapturePhase.auto, -5);
    expect(capture.fuel(CapturePhase.auto), 7);
    capture.undo();
    expect(capture.fuel(CapturePhase.auto), 12);
  });

  test('counts use existing API limits and phases', () {
    expect(
        capture.score(
            quantity: 4, phase: CapturePhase.auto, startMs: 0, durationMs: 1),
        isFalse);
    capture.route('Preload Right');
    capture.score(
        quantity: 400, phase: CapturePhase.auto, startMs: 0, durationMs: 1);
    capture.correctFuel(CapturePhase.auto, 100);
    expect(capture.fuel(CapturePhase.auto), 300);
    capture.correctFuel(CapturePhase.auto, -400);
    expect(capture.fuel(CapturePhase.auto), 0);
    capture.correctFuel(CapturePhase.teleop, 2000);
    capture.correctFuel(CapturePhase.delay, 100);
    expect(capture.fuel(CapturePhase.teleop), 1000);
    expect(capture.fuel(CapturePhase.delay), 0);
  });

  test(
      'serialized recording restores clock and flags, without extra API fields',
      () {
    capture.route('Preload Left');
    capture.start();
    capture.score(
        quantity: 9, phase: CapturePhase.auto, startMs: 1000, durationMs: 1000);
    capture.syncClock(60);
    capture.score(
        quantity: 25,
        phase: CapturePhase.teleop,
        startMs: 50000,
        durationMs: 10000);
    capture.flag(CaptureKind.defense, true, startMs: 40000, durationMs: 9000);
    capture.flag(CaptureKind.disabled, true);
    final restored = ScoutingCapture(clock: () => now)
      ..restore(
          jsonDecode(jsonEncode(capture.toJson())) as Map<String, dynamic>);
    addTearDown(restored.dispose);
    expect(restored.apiData, capture.apiData);
    expect(restored.defenseMs, 9000);
    expect(restored.phase, CapturePhase.teleop);
    expect(
        restored.apiData.keys,
        unorderedEquals(
            ['autoPath', 'autoScouting', 'teleopScouting', 'misc']));
    final report = MatchScouting2026(
        event: '2026test',
        match: '1',
        team: 123,
        groupId: 'group',
        data: Data.fromJson(jsonDecode(jsonEncode({
          ...restored.apiData,
          'misc': {
            ...restored.apiData['misc'] as Map,
            'comments': 'Observed defense'
          }
        })) as Map<String, dynamic>),
        scoutInfo: const ScoutInfo(
            userId: 'scout',
            firstName: 'Scout',
            username: 'scout',
            team: '123'));
    final payload =
        jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;
    expect(
        MatchScouting2026.fromJson(payload).data.autoScouting.fuel_scored, 9);
    expect(jsonEncode(payload), isNot(contains('durationMs')));
    restored.undo();
    expect(restored.disabled, isFalse);
  });

  test('a corrupt snapshot leaves the existing journal intact', () {
    capture.route('Preload Left');
    final invalid = capture.toJson();
    (invalid['actions'] as List).add(const CaptureAction(
            kind: CaptureKind.route,
            phase: CapturePhase.auto,
            elapsedMs: 5,
            route: 'invalid')
        .toJson());
    expect(() => capture.restore(invalid), throwsFormatException);
    expect(capture.autoPath, ['Preload Left']);
    final negative = capture.toJson();
    (negative['actions'] as List).add(const CaptureAction(
            kind: CaptureKind.shooting,
            phase: CapturePhase.auto,
            elapsedMs: -1,
            quantity: 3)
        .toJson());
    expect(() => capture.restore(negative), throwsFormatException);
    expect(capture.actions.length, 1);
  });
}
