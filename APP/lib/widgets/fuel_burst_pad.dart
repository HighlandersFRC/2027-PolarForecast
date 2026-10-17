import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:app/models/scouting_capture.dart';
import 'matte_theme.dart';

enum FuelCountingMode { rate, count }

/// Independent Flutter implementation of hold/drag burst collection. A pointer
/// cancellation or app suspension never leaves an unseen counting timer alive.
class FuelBurstPad extends StatefulWidget {
  final FuelCountingMode mode;
  final CapturePhase phase;
  final bool enabled;
  final int maximum;
  final bool compact;
  final int Function() elapsedMs;
  final void Function(
      int count, int durationMs, int startedMs, CapturePhase phase) onCommit;
  const FuelBurstPad(
      {super.key,
      required this.mode,
      required this.phase,
      required this.elapsedMs,
      required this.onCommit,
      this.enabled = true,
      this.compact = false,
      this.maximum = 300});
  @override
  State<FuelBurstPad> createState() => _FuelBurstPadState();
}

class _FuelBurstPadState extends State<FuelBurstPad>
    with WidgetsBindingObserver {
  Timer? _timer;
  final _duration = Stopwatch();
  int? _pointer;
  Offset _origin = Offset.zero;
  double _distance = 0;
  double _accumulator = 0;
  int _count = 0;
  int _lastTick = 0;
  int _startedMs = 0;
  CapturePhase _phase = CapturePhase.auto;
  bool get _active => _pointer != null;
  double get _rate => 2 + (_distance / 180).clamp(0, 1) * 18;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancel();
  }

  @override
  void didUpdateWidget(covariant FuelBurstPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_active &&
        (oldWidget.phase != widget.phase ||
            !widget.enabled ||
            oldWidget.mode != widget.mode)) {
      final result = _take();
      final commit = widget.onCommit;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (result != null) commit(result.$1, result.$2, result.$3, result.$4);
      });
    }
  }

  void _begin(PointerDownEvent event) {
    if (!widget.enabled || _active || widget.maximum <= 0) return;
    _pointer = event.pointer;
    _origin = event.localPosition;
    _distance = 0;
    _startedMs = widget.elapsedMs();
    _phase = widget.phase;
    _accumulator = 0;
    _lastTick = 0;
    _count = 1;
    _duration
      ..reset()
      ..start();
    HapticFeedback.selectionClick();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_active) return;
      final elapsed = _duration.elapsedMilliseconds;
      if (widget.mode == FuelCountingMode.rate) {
        _accumulator += _rate * (elapsed - _lastTick) / 1000;
        final next = math.min(widget.maximum, 1 + _accumulator.floor());
        if (next != _count) {
          _count = next;
          HapticFeedback.selectionClick();
        }
      }
      _lastTick = elapsed;
      setState(() {});
    });
    setState(() {});
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    setState(() {
      _distance = (event.localPosition - _origin).distance;
      if (widget.mode == FuelCountingMode.count)
        _count = (1 + (_distance / 10).floor()).clamp(1, widget.maximum);
    });
  }

  (int, int, int, CapturePhase)? _take() {
    if (!_active) return null;
    final result = (_count, _duration.elapsedMilliseconds, _startedMs, _phase);
    _timer?.cancel();
    _timer = null;
    _duration.stop();
    _pointer = null;
    _count = 0;
    return result;
  }

  void _end(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final result = _take();
    setState(() {});
    if (result != null)
      widget.onCommit(result.$1, result.$2, result.$3, result.$4);
  }

  void _cancel() {
    _take();
    if (mounted) setState(() {});
  }

  void _single() {
    if (widget.enabled && widget.maximum > 0 && !_active) {
      widget.onCommit(1, 0, widget.elapsedMs(), widget.phase);
    }
  }

  @override
  void dispose() {
    // A phase change replaces the field controls. Commit the burst once instead
    // of losing the fuel held across that boundary or when returning to review.
    final result = _take();
    final commit = widget.onCommit;
    if (result != null)
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => commit(result.$1, result.$2, result.$3, result.$4));
    _timer?.cancel();
    _duration.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: widget.enabled,
        label: 'Record shooting burst. Hold and drag, release to save.',
        onTap: widget.enabled ? _single : null,
        child: FocusableActionDetector(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
                _single();
                return null;
              }),
            },
            child: RawGestureDetector(
                gestures: widget.enabled
                    ? {
                        EagerGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                                    EagerGestureRecognizer>(
                                () => EagerGestureRecognizer(), (_) {}),
                      }
                    : const {},
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _begin,
                  onPointerMove: _move,
                  onPointerUp: _end,
                  onPointerCancel: (event) {
                    if (event.pointer == _pointer) _cancel();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    constraints:
                        BoxConstraints(minHeight: widget.compact ? 72 : 126),
                    decoration: BoxDecoration(
                        color: widget.enabled
                            ? (_active
                                ? const Color(0xFF77E6A0)
                                : const Color(0xFF204D38))
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _active
                                ? Colors.white
                                : const Color(0xFF77E6A0).withValues(
                                    alpha: widget.enabled ? 0.6 : 0.15),
                            width: 2)),
                    padding: EdgeInsets.all(widget.compact ? 4 : 12),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_active)
                            SizedBox(
                                height: widget.compact ? 28 : 48,
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('$_count',
                                        style: const TextStyle(
                                            color: AppColors.background,
                                            fontSize: 48,
                                            height: 1,
                                            fontWeight: FontWeight.w900))))
                          else
                            Icon(Icons.hexagon_outlined,
                                color: const Color(0xFF77E6A0),
                                size: widget.compact ? 24 : 38),
                          SizedBox(height: widget.compact ? 2 : 6),
                          if (widget.compact)
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    _active ? 'Release to save' : 'HUB · HOLD',
                                    style: TextStyle(
                                        color: _active
                                            ? AppColors.background
                                            : AppColors.text,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)))
                          else
                            Text(
                                _active
                                    ? 'Release to record fuel'
                                    : 'SHOOT FUEL',
                                style: TextStyle(
                                    color: _active
                                        ? AppColors.background
                                        : AppColors.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                          if (!widget.compact) ...[
                            const SizedBox(height: 3),
                            Text(
                                _active
                                    ? '${(_duration.elapsedMilliseconds / 1000).toStringAsFixed(1)}s · ${widget.mode == FuelCountingMode.rate ? '${_rate.toStringAsFixed(0)} fuel/s' : 'distance sets count'}'
                                    : 'Hold & drag · ${widget.mode.name} mode',
                                style: TextStyle(
                                    color: _active
                                        ? AppColors.background
                                        : AppColors.textMuted,
                                    fontSize: 11)),
                          ],
                        ]),
                  ),
                ))),
      );
}
