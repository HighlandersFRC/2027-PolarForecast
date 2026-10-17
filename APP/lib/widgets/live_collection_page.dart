import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:app/models/auto_route.dart';
import 'package:app/models/scouting_capture.dart';
import 'fuel_burst_pad.dart';
import 'auto_field_map.dart';
import 'matte_theme.dart';

/// Field-relative, contextual recording adapted from Lovat's collection flow.
/// All source here is an independent Flutter implementation for PolarForecast.
class LiveCollectionPage extends StatefulWidget {
  final ScoutingCapture capture;
  final int team;
  final String match;
  final bool blue;
  final String Function()? backupStatus;
  const LiveCollectionPage(
      {super.key,
      required this.capture,
      required this.team,
      required this.match,
      required this.blue,
      this.backupStatus});
  @override
  State<LiveCollectionPage> createState() => _LiveCollectionPageState();
}

class _LiveCollectionPageState extends State<LiveCollectionPage> {
  FuelCountingMode _mode = FuelCountingMode.rate;
  bool _flipped = false;
  Timer? _clock;
  ScoutingCapture get capture => widget.capture;
  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
        const Duration(milliseconds: 250), (_) => capture.tick());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String get _phaseLabel => switch (capture.phase) {
        CapturePhase.setup => 'Pre-match',
        CapturePhase.auto => 'Autonomous',
        CapturePhase.delay => 'Scoring delay',
        CapturePhase.teleop => capture.endgame ? 'Endgame' : 'Teleop',
        CapturePhase.review => 'Post-match',
      };
  String get _time =>
      '${capture.secondsRemaining ~/ 60}:${(capture.secondsRemaining % 60).toString().padLeft(2, '0')}';

  void _route(String action) {
    final error = capture.route(action);
    HapticFeedback.selectionClick();
    if (error != null)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _end() async {
    final end = capture.phase == CapturePhase.review ||
        await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('Finish this match?'),
                      content: const Text(
                          'Your observations stay in the draft for post-match review.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Keep recording')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Review match'))
                      ],
                    )) ==
            true;
    if (!end || !mounted) return;
    capture.finish();
    Navigator.pop(context);
  }

  Future<void> _sync() async {
    var phase = capture.phase == CapturePhase.teleop
        ? CapturePhase.teleop
        : CapturePhase.auto;
    final controller =
        TextEditingController(text: '${capture.secondsRemaining}');
    final remaining = await showDialog<(CapturePhase, int)>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (_, setDialogState) => AlertDialog(
                  title: const Text('Match the field clock'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<CapturePhase>(
                        initialValue: phase,
                        decoration:
                            const InputDecoration(labelText: 'Field phase'),
                        items: const [
                          DropdownMenuItem(
                              value: CapturePhase.auto, child: Text('Auto')),
                          DropdownMenuItem(
                              value: CapturePhase.teleop, child: Text('Teleop'))
                        ],
                        onChanged: (value) => setDialogState(() {
                              phase = value!;
                              controller.text =
                                  phase == CapturePhase.auto ? '20' : '140';
                            })),
                    const SizedBox(height: 12),
                    TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Seconds remaining')),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          final seconds = int.tryParse(controller.text);
                          if (seconds == null ||
                              seconds < 0 ||
                              seconds > (phase == CapturePhase.auto ? 20 : 140))
                            return;
                          Navigator.pop(context, (phase, seconds));
                        },
                        child: const Text('Sync'))
                  ],
                )));
    controller.dispose();
    if (remaining != null && mounted)
      capture.syncClock(remaining.$1 == CapturePhase.auto
          ? 20 - remaining.$2
          : 23 + 140 - remaining.$2);
  }

  Widget _fuelPad(CapturePhase phase, {bool compact = false}) => FuelBurstPad(
        compact: compact,
        key: const ValueKey('live-shooting-pad'),
        mode: _mode,
        phase: phase,
        enabled: (phase == CapturePhase.auto || phase == CapturePhase.teleop) &&
            (phase != CapturePhase.auto || capture.autoPath.isNotEmpty),
        maximum:
            (phase == CapturePhase.auto ? 300 : 1000) - capture.fuel(phase),
        elapsedMs: () => capture.elapsedMs,
        onCommit: (count, duration, started, capturedPhase) => capture.score(
            quantity: count,
            phase: capturedPhase,
            startMs: started,
            durationMs: duration),
      );

  Widget _autoField() => AutoFieldMap(
        path: capture.autoPath,
        blue: widget.blue,
        flipped: _flipped,
        onRotate: () => setState(() => _flipped = !_flipped),
        keyPrefix: 'field',
        enabled: capture.phase == CapturePhase.setup ||
            capture.phase == CapturePhase.auto,
        preloadOnly: capture.phase == CapturePhase.setup,
        hubEnabled: !capture.neutralZone,
        onAction: _route,
        hubControl: capture.phase == CapturePhase.auto &&
                capture.autoPath.isNotEmpty &&
                !capture.neutralZone
            ? _fuelPad(CapturePhase.auto, compact: true)
            : null,
      );

  Widget _teleop() => LayoutBuilder(builder: (context, constraints) {
        final score = _fuelPad(CapturePhase.teleop);
        final observations =
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HoldDefensePad(
              enabled: capture.phase == CapturePhase.teleop,
              onCommit: (duration) => capture.flag(CaptureKind.defense, true,
                  durationMs: duration,
                  startMs: capture.elapsedMs - duration,
                  capturedPhase: CapturePhase.teleop)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: () =>
                  capture.flag(CaptureKind.disabled, !capture.disabled),
              icon: Icon(capture.disabled
                  ? Icons.check_circle_rounded
                  : Icons.power_settings_new_rounded),
              label: Text(
                  capture.disabled ? 'Disabled recorded' : 'Robot disabled'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  foregroundColor: const Color(0xFFFFA0AA))),
        ]);
        if (constraints.maxWidth > 650)
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: score),
            const SizedBox(width: 16),
            Expanded(child: observations)
          ]);
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [score, const SizedBox(height: 14), observations]);
      });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: capture,
      builder: (context, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
                titleSpacing: 0,
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team ${widget.team} · Match ${widget.match}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(
                          '${widget.blue ? 'Blue' : 'Red'} · $_phaseLabel${capture.started ? ' · $_time' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: capture.endgame
                                  ? const Color(0xFFFFD28A)
                                  : widget.blue
                                      ? const Color(0xFF9CC9FF)
                                      : const Color(0xFFFFA0AA))),
                    ]),
                actions: [
                  IconButton(
                      tooltip: 'Undo last observation',
                      onPressed: capture.canUndo ? capture.undo : null,
                      icon: const Icon(Icons.undo_rounded)),
                  PopupMenuButton<String>(
                      tooltip: 'Recording options',
                      onSelected: (value) {
                        if (value == 'flip')
                          setState(() => _flipped = !_flipped);
                        if (value == 'sync') _sync();
                        if (value == 'history')
                          showCaptureTimeline(context, capture);
                        if (value == 'redo') capture.redo();
                      },
                      itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'history',
                                child: Text('Observation timeline')),
                            const PopupMenuItem(
                                value: 'flip', child: Text('Flip field view')),
                            if (capture.started)
                              const PopupMenuItem(
                                  value: 'sync',
                                  child: Text('Sync field clock')),
                            if (capture.canRedo)
                              const PopupMenuItem(
                                  value: 'redo',
                                  child: Text('Redo observation')),
                          ]),
                ]),
            body: SafeArea(
                top: false,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('AUTO ${capture.fuel(CapturePhase.auto)}',
                                    style: const TextStyle(
                                        color: Color(0xFFFFD28A),
                                        fontWeight: FontWeight.w800)),
                                Text(
                                    'TELEOP ${capture.fuel(CapturePhase.teleop)}',
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w800)),
                                for (final mode in FuelCountingMode.values)
                                  ChoiceChip(
                                      label: Text(mode == FuelCountingMode.rate
                                          ? 'Rate'
                                          : 'Count'),
                                      selected: _mode == mode,
                                      onSelected: (_) =>
                                          setState(() => _mode = mode)),
                              ]),
                          const SizedBox(height: 12),
                          if (capture.phase == CapturePhase.setup) ...[
                            _autoField(),
                            const SizedBox(height: 12),
                            if (capture.autoPath.isNotEmpty)
                              Text(
                                  '${AutoRoute.label(capture.autoPath.first)} selected',
                                  style: const TextStyle(
                                      color: AppColors.primary)),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                key: const ValueKey('start-live-match'),
                                onPressed: capture.start,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start match clock'),
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(64))),
                            const SizedBox(height: 10),
                            const Text(
                                'Tap on the field start signal. The controls change with the clock; sync it from the menu if you start late.',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.5)),
                          ] else if (capture.phase == CapturePhase.auto)
                            _autoField()
                          else if (capture.phase == CapturePhase.delay)
                            const MattePanel(
                                padding: EdgeInsets.all(32),
                                child: Column(children: [
                                  Icon(Icons.hourglass_bottom_rounded,
                                      color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Text('Auto scoring delay',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 6),
                                  Text(
                                      'Teleop controls open after the 3-second delay.',
                                      textAlign: TextAlign.center)
                                ]))
                          else if (capture.phase == CapturePhase.teleop)
                            _teleop()
                          else
                            const MattePanel(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'Match complete. Review observations and add any final notes.')),
                          if (capture.phase == CapturePhase.auto ||
                              capture.phase == CapturePhase.teleop) ...[
                            const SizedBox(height: 14),
                            const Text(
                                'Hold the green hub on the map during auto, or the green pad during teleop, while fuel scores. Drag farther for a faster rate, or select Count to set the burst quantity by distance. Release to save.',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    height: 1.4)),
                            const SizedBox(height: 8),
                            const Text('Fuel correction',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            Wrap(spacing: 6, children: [
                              for (final delta in [-5, -1, 1, 5])
                                Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: SizedBox(
                                        width: 48,
                                        child: OutlinedButton(
                                            onPressed: () =>
                                                capture.correctFuel(
                                                    capture.phase, delta),
                                            style: OutlinedButton.styleFrom(
                                                padding: EdgeInsets.zero),
                                            child: Text(
                                                '${delta > 0 ? '+' : ''}$delta')))),
                            ]),
                          ],
                          const SizedBox(height: 12),
                          if (widget.backupStatus != null)
                            Text(widget.backupStatus!(),
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 10)),
                        ]))),
            bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                        onPressed: _end,
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Finish & review')))),
          ));
}

Future<void> showCaptureTimeline(
        BuildContext context, ScoutingCapture capture) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: AnimatedBuilder(
            animation: capture,
            builder: (context, _) => Column(children: [
                  const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Observation timeline',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800))),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                          'Times and durations are retained on this device. The server receives fuel totals, auto actions, and observations.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11))),
                  Expanded(
                      child: capture.actions.isEmpty
                          ? const Center(child: Text('No observations yet'))
                          : ListView.builder(
                              itemCount: capture.actions.length,
                              itemBuilder: (_, i) {
                                final action = capture.actions[i];
                                return ListTile(
                                    leading: Text(
                                        '${(action.elapsedMs / 1000).toStringAsFixed(1)}s',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12)),
                                    title: Text(
                                        action.kind == CaptureKind.route
                                            ? AutoRoute.label(action.route!)
                                            : action.kind ==
                                                    CaptureKind.shooting
                                                ? '${action.quantity} fuel · shooting burst'
                                                : action.kind ==
                                                        CaptureKind.correction
                                                    ? '${action.quantity > 0 ? '+' : ''}${action.quantity} fuel correction'
                                                    : '${action.kind.name} ${action.quantity == 1 ? 'recorded' : 'cleared'}',
                                        style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(
                                        '${action.phase.name}${action.durationMs > 0 ? ' · ${(action.durationMs / 1000).toStringAsFixed(1)}s duration' : ''}',
                                        style: const TextStyle(fontSize: 11)));
                              })),
                  TextButton.icon(
                      onPressed: capture.canUndo ? capture.undo : null,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo last observation')),
                ])),
      )),
    );

class HoldDefensePad extends StatefulWidget {
  final bool enabled;
  final ValueChanged<int> onCommit;
  const HoldDefensePad(
      {super.key, required this.enabled, required this.onCommit});
  @override
  State<HoldDefensePad> createState() => _HoldDefensePadState();
}

class _HoldDefensePadState extends State<HoldDefensePad>
    with WidgetsBindingObserver {
  final _clock = Stopwatch();
  Timer? _timer;
  int? _pointer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancel() {
    _pointer = null;
    _timer?.cancel();
    _clock.stop();
    if (mounted) setState(() {});
  }

  void _finish() {
    if (_pointer == null) return;
    final duration = _clock.elapsedMilliseconds;
    _cancel();
    if (duration > 0) widget.onCommit(duration);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancel();
  }

  @override
  void didUpdateWidget(covariant HoldDefensePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pointer != null && !widget.enabled)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finish();
      });
  }

  @override
  void dispose() {
    final duration = _clock.elapsedMilliseconds;
    final commit = widget.onCommit;
    if (_pointer != null && duration > 0)
      WidgetsBinding.instance.addPostFrameCallback((_) => commit(duration));
    _timer?.cancel();
    _clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      label: 'Hold while playing defense',
      child: RawGestureDetector(
          gestures: widget.enabled
              ? {
                  EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                          EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(), (_) {}),
                }
              : const {},
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (!widget.enabled || _pointer != null) return;
              _pointer = event.pointer;
              _clock
                ..reset()
                ..start();
              _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
                if (mounted) setState(() {});
              });
              setState(() {});
            },
            onPointerUp: (event) {
              if (event.pointer == _pointer) _finish();
            },
            onPointerCancel: (event) {
              if (event.pointer == _pointer) _cancel();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 90),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _pointer == null
                      ? AppColors.surfaceRaised
                      : const Color(0xFF514525),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFFD28A).withValues(alpha: 0.4))),
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFFFD28A)),
                const SizedBox(height: 6),
                Text(
                    _pointer == null
                        ? 'Hold while defending'
                        : '${(_clock.elapsedMilliseconds / 1000).toStringAsFixed(1)}s · defending',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13))
              ]),
            ),
          )));
}
