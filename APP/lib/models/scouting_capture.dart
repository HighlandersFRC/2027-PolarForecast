import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'auto_route.dart';

enum CapturePhase { setup, auto, delay, teleop, review }

enum CaptureKind { route, shooting, correction, defense, disabled }

class CaptureAction {
  final CaptureKind kind;
  final CapturePhase phase;
  final int elapsedMs;
  final int durationMs;
  final int quantity;
  final String? route;
  const CaptureAction(
      {required this.kind,
      required this.phase,
      required this.elapsedMs,
      this.durationMs = 0,
      this.quantity = 0,
      this.route});

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'phase': phase.name,
        'elapsedMs': elapsedMs,
        'durationMs': durationMs,
        'quantity': quantity,
        if (route != null) 'route': route
      };
  factory CaptureAction.fromJson(Map<String, dynamic> json) => CaptureAction(
      kind: CaptureKind.values.byName(json['kind'] as String),
      phase: CapturePhase.values.byName(json['phase'] as String),
      elapsedMs: (json['elapsedMs'] as num).toInt(),
      durationMs: (json['durationMs'] as num? ?? 0).toInt(),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      route: json['route'] as String?);
}

/// An observation journal. Only [apiData] is sent to PolarForecast's existing
/// endpoint. Timestamps and durations are device-local, never invented fields.
class ScoutingCapture extends ChangeNotifier {
  final DateTime Function() now;
  ScoutingCapture({DateTime Function()? clock}) : now = clock ?? DateTime.now;
  final List<CaptureAction> _actions = [];
  final List<List<CaptureAction>> _past = [];
  final List<List<CaptureAction>> _future = [];
  DateTime? _started;
  int? _finishedAt;
  CapturePhase _lastPhase = CapturePhase.setup;
  int revision = 0;
  bool isDisposed = false;
  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }

  UnmodifiableListView<CaptureAction> get actions =>
      UnmodifiableListView(_actions);
  bool get started => _started != null;
  int get elapsedMs =>
      _finishedAt ??
      (_started == null
          ? 0
          : now().difference(_started!).inMilliseconds.clamp(0, 163000));
  CapturePhase get phase {
    if (_finishedAt != null) return CapturePhase.review;
    if (!started) return CapturePhase.setup;
    if (elapsedMs < 20000) return CapturePhase.auto;
    if (elapsedMs < 23000) return CapturePhase.delay;
    if (elapsedMs < 163000) return CapturePhase.teleop;
    return CapturePhase.review;
  }

  bool get endgame => phase == CapturePhase.teleop && elapsedMs >= 133000;
  int get secondsRemaining {
    final boundary = switch (phase) {
      CapturePhase.auto => 20000,
      CapturePhase.delay => 23000,
      CapturePhase.teleop => 163000,
      _ => 0
    };
    return ((boundary - elapsedMs).clamp(0, 163000) / 1000).ceil();
  }

  bool get canUndo => _actions.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  List<String> get autoPath => [
        for (final action in _actions)
          if (action.kind == CaptureKind.route && action.route != null)
            action.route!
          else if (action.kind == CaptureKind.shooting &&
              action.phase == CapturePhase.auto)
            AutoRoute.shot
      ];
  int fuel(CapturePhase phase) => _actions
      .where((a) =>
          a.phase == phase &&
          (a.kind == CaptureKind.shooting || a.kind == CaptureKind.correction))
      .fold(0, (sum, a) => sum + a.quantity);
  bool get defense => _flag(CaptureKind.defense);
  bool get disabled => _flag(CaptureKind.disabled);
  bool _flag(CaptureKind kind) =>
      _actions.where((a) => a.kind == kind).lastOrNull?.quantity == 1;
  int get defenseMs => _actions
      .where((a) => a.kind == CaptureKind.defense)
      .fold(0, (sum, a) => sum + a.durationMs);
  bool get neutralZone =>
      autoPath.where(AutoRoute.crossings.contains).length.isOdd;

  void _changed() {
    revision++;
    notifyListeners();
  }

  void _remember() {
    _past.add(List.of(_actions));
    _future.clear();
  }

  void start() {
    if (started) return;
    _started = now();
    _lastPhase = phase;
    _changed();
  }

  void tick() {
    if (!started) return;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      revision++;
    }
    notifyListeners();
  }

  void syncClock(int elapsedSeconds) {
    _started = now().subtract(Duration(seconds: elapsedSeconds.clamp(0, 163)));
    _finishedAt = null;
    _lastPhase = phase;
    _changed();
  }

  void finish() {
    _finishedAt = elapsedMs;
    _lastPhase = CapturePhase.review;
    _changed();
  }

  String? route(String value) {
    final error = AutoRoute.blockedReason(autoPath, value);
    if (error != null) return error;
    _remember();
    _actions.add(CaptureAction(
        kind: CaptureKind.route,
        phase: CapturePhase.auto,
        elapsedMs: elapsedMs,
        route: value));
    _changed();
    return null;
  }

  bool score(
      {required int quantity,
      required CapturePhase phase,
      required int startMs,
      required int durationMs}) {
    if (isDisposed) return false;
    if (phase != CapturePhase.auto && phase != CapturePhase.teleop)
      return false;
    if (phase == CapturePhase.auto && autoPath.isEmpty) return false;
    final accepted = quantity.clamp(
        0, (phase == CapturePhase.auto ? 300 : 1000) - fuel(phase));
    if (accepted <= 0) return false;
    _remember();
    _actions.add(CaptureAction(
        kind: CaptureKind.shooting,
        phase: phase,
        elapsedMs: startMs.clamp(0, 163000),
        durationMs: durationMs.clamp(0, 163000),
        quantity: accepted));
    _changed();
    return true;
  }

  void correctFuel(CapturePhase phase, int delta) {
    if (phase != CapturePhase.auto && phase != CapturePhase.teleop) return;
    final current = fuel(phase);
    final accepted =
        (current + delta).clamp(0, phase == CapturePhase.auto ? 300 : 1000) -
            current;
    if (accepted == 0) return;
    _remember();
    _actions.add(CaptureAction(
        kind: CaptureKind.correction,
        phase: phase,
        elapsedMs: elapsedMs,
        quantity: accepted));
    _changed();
  }

  void flag(CaptureKind kind, bool value,
      {int durationMs = 0, int? startMs, CapturePhase? capturedPhase}) {
    if (isDisposed) return;
    assert(kind == CaptureKind.defense || kind == CaptureKind.disabled);
    _remember();
    _actions.add(CaptureAction(
        kind: kind,
        phase: capturedPhase ?? phase,
        elapsedMs: (startMs ?? elapsedMs).clamp(0, 163000),
        durationMs: durationMs.clamp(0, 163000),
        quantity: value ? 1 : 0));
    _changed();
  }

  void undo() {
    if (_actions.isEmpty) return;
    _future.add(List.of(_actions));
    final previous = _past.isNotEmpty
        ? _past.removeLast()
        : _actions.take(_actions.length - 1).toList();
    _actions
      ..clear()
      ..addAll(previous);
    _changed();
  }

  void redo() {
    if (_future.isEmpty) return;
    _past.add(List.of(_actions));
    _actions
      ..clear()
      ..addAll(_future.removeLast());
    _changed();
  }

  void reset() {
    _actions.clear();
    _past.clear();
    _future.clear();
    _started = null;
    _finishedAt = null;
    _lastPhase = CapturePhase.setup;
    _changed();
  }

  Map<String, dynamic> get apiData => {
        'autoPath': {'path': autoPath},
        'autoScouting': {'fuel_scored': fuel(CapturePhase.auto)},
        'teleopScouting': {'fuel_scored': fuel(CapturePhase.teleop)},
        'misc': {'died': disabled, 'defense': defense},
      };
  Map<String, dynamic> toJson() => {
        'version': 1,
        'started': _started?.toUtc().toIso8601String(),
        'finishedAt': _finishedAt,
        'actions': _actions.map((a) => a.toJson()).toList()
      };
  void restore(Map<String, dynamic> json) {
    if (json['version'] != 1)
      throw const FormatException('Unsupported recording version');
    final actions = (json['actions'] as List)
        .map((a) => CaptureAction.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();
    // Validate a complete snapshot before replacing an in-progress draft.
    final check = ScoutingCapture(clock: now).._actions.addAll(actions);
    final error = AutoRoute.validate(check.autoPath);
    final valid = error == null &&
        check.fuel(CapturePhase.auto) >= 0 &&
        check.fuel(CapturePhase.auto) <= 300 &&
        check.fuel(CapturePhase.teleop) >= 0 &&
        check.fuel(CapturePhase.teleop) <= 1000 &&
        actions.every((a) =>
            a.elapsedMs >= 0 &&
            a.elapsedMs <= 163000 &&
            a.durationMs >= 0 &&
            a.durationMs <= 163000 &&
            (a.kind != CaptureKind.shooting ||
                (a.quantity > 0 &&
                    (a.phase == CapturePhase.auto ||
                        a.phase == CapturePhase.teleop))) &&
            ((a.kind != CaptureKind.defense &&
                    a.kind != CaptureKind.disabled) ||
                (a.quantity == 0 || a.quantity == 1))) &&
        ((json['finishedAt'] as num?) == null ||
            ((json['finishedAt'] as num) >= 0 &&
                (json['finishedAt'] as num) <= 163000));
    check.dispose();
    if (!valid) throw const FormatException('Invalid recording data');
    final start = json['started'] == null
        ? null
        : DateTime.parse(json['started'] as String);
    _actions
      ..clear()
      ..addAll(actions);
    _past.clear();
    _future.clear();
    _started = start;
    _finishedAt = (json['finishedAt'] as num?)?.toInt();
    _lastPhase = phase;
    _changed();
  }
}
