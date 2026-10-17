import 'dart:math' as math;
import 'package:app/models/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'matte_theme.dart';

/// Field landmarks, rather than a measured robot trace. Coordinates are only
/// for presentation; recording still emits the original API action strings.
class AutoFieldMap extends StatelessWidget {
  final List<String> path;
  final bool blue;
  final bool flipped;
  final bool enabled;
  final bool preloadOnly;
  final bool hubEnabled;
  final ValueChanged<String>? onAction;
  final Widget? hubControl;
  final String keyPrefix;
  final VoidCallback? onRotate;
  const AutoFieldMap(
      {super.key,
      required this.path,
      this.blue = false,
      this.flipped = false,
      this.enabled = true,
      this.preloadOnly = false,
      this.hubEnabled = true,
      this.onAction,
      this.hubControl,
      this.keyPrefix = 'route',
      this.onRotate});

  static const positions = <String, Offset>{
    'Preload Left': Offset(.25, .10),
    'Preload Center': Offset(.25, .50),
    'Preload Right': Offset(.25, .90),
    'Went Under Left Trench': Offset(.56, .075),
    'Went Over Left Bump': Offset(.56, .295),
    'Went Over Right Bump': Offset(.56, .74),
    'Went Under Right Trench': Offset(.56, .93),
    AutoRoute.depot: Offset(.095, .28),
    AutoRoute.neutral: Offset(.88, .50),
    AutoRoute.shot: Offset(.56, .505),
  };

  // The asset names predate this recorder: Full is the red half-field,
  // Blue is the blue half-field, and Red contains the complete field.
  String get asset => blue
      ? 'assets/2026FRCFeildImageBlue.png'
      : 'assets/2026FRCFeildImageFull.png';
  Color get accent => blue ? const Color(0xFF94BEFF) : const Color(0xFFFF929E);
  bool get neutral => path.where(AutoRoute.crossings.contains).length.isOdd;
  bool get rotated => blue != flipped;
  Offset viewPoint(Offset point) =>
      rotated ? Offset(1 - point.dx, 1 - point.dy) : point;

  String _name(String action) => switch (action) {
        'Preload Left' => 'Preload\nleft',
        'Preload Center' => 'Preload\ncenter',
        'Preload Right' => 'Preload\nright',
        'Went Under Left Trench' => 'Left\ntrench',
        'Went Over Left Bump' => 'Left\nbump',
        'Went Over Right Bump' => 'Right\nbump',
        'Went Under Right Trench' => 'Right\ntrench',
        AutoRoute.depot => 'Depot\nintake',
        AutoRoute.neutral => 'Neutral\nintake',
        AutoRoute.shot => 'Hub\nshoot',
        _ => action,
      };

  @override
  Widget build(BuildContext context) => Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${blue ? 'BLUE' : 'RED'} AUTO FIELD',
                      style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                      path.isEmpty
                          ? 'Tap a preload area'
                          : 'Recorded zone: ${neutral ? 'neutral' : 'alliance'}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ])),
            if (onRotate != null)
              TextButton.icon(
                  onPressed: onRotate,
                  icon: const Icon(Icons.screen_rotation_alt_rounded, size: 18),
                  label: const Text('Rotate'),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
          ]),
          const SizedBox(height: 6),
          Text(
              rotated
                  ? 'Top = right lane · bottom = left lane'
                  : 'Top = left lane · bottom = right lane',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          RepaintBoundary(child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width * 1383 / (blue ? 1438 : 1414);
            Offset point(Offset p) {
              final v = viewPoint(p);
              return Offset(v.dx * width, v.dy * height);
            }

            Widget placed(String action, Widget child,
                {double targetWidth = 80, double targetHeight = 48}) {
              final center = point(positions[action]!);
              return Positioned(
                  left: (center.dx - targetWidth / 2)
                      .clamp(3, width - targetWidth - 3),
                  top: (center.dy - targetHeight / 2)
                      .clamp(3, height - targetHeight - 3),
                  width: targetWidth,
                  height: targetHeight,
                  child: child);
            }

            Widget target(String action) {
              final reason = AutoRoute.blockedReason(path, action);
              final available = enabled &&
                  onAction != null &&
                  reason == null &&
                  (!preloadOnly || AutoRoute.isPreload(action)) &&
                  (action != AutoRoute.shot || hubEnabled);
              final selected = path.isNotEmpty && path.last == action;
              final color = action == AutoRoute.shot
                  ? const Color(0xFF77E6A0)
                  : AutoRoute.crossings.contains(action)
                      ? const Color(0xFFDED0FF)
                      : const Color(0xFFFFD28A);
              return Tooltip(
                  message: reason ??
                      (preloadOnly && !AutoRoute.isPreload(action)
                          ? 'Start the match clock to record actions'
                          : 'Record ${AutoRoute.label(action)}'),
                  child: FilledButton(
                    key: ValueKey('$keyPrefix-action-$action'),
                    onPressed: available ? () => onAction!(action) : null,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 3),
                        minimumSize: const Size(48, 48),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor:
                            selected ? color : const Color(0xF21C2635),
                        foregroundColor:
                            selected ? AppColors.background : color,
                        disabledBackgroundColor: const Color(0xE019202C),
                        disabledForegroundColor: color.withValues(alpha: .65),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                            side: BorderSide(
                                color: available
                                    ? color
                                    : color.withValues(alpha: .3),
                                width: selected ? 2 : 1))),
                    child: Semantics(
                        label: AutoRoute.label(action),
                        excludeSemantics: true,
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_name(action),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.fontFamily,
                                    fontSize: 11,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800)))),
                  ));
            }

            return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  key: ValueKey('$keyPrefix-field'),
                  width: width,
                  height: height,
                  child: Stack(children: [
                    Positioned.fill(
                        child: ColoredBox(
                            color: const Color(0xFF232E3C),
                            child: RotatedBox(
                                quarterTurns:
                                    (blue ? 2 : 0) + (rotated ? 2 : 0),
                                child: Image.asset(asset,
                                    key: ValueKey('$keyPrefix-field-image'),
                                    fit: BoxFit.fill,
                                    excludeFromSemantics: true,
                                    filterQuality: FilterQuality.medium)))),
                    Positioned.fill(
                        child: IgnorePointer(
                            child: CustomPaint(
                                painter: _FieldRoutePainter(
                                    path, accent, rotated)))),
                    for (final action in AutoRoute.crossings)
                      placed(action, target(action)),
                    if (path.isEmpty) ...[
                      for (final action in AutoRoute.preloads)
                        placed(action, target(action), targetWidth: 86),
                    ],
                    placed(AutoRoute.depot, target(AutoRoute.depot),
                        targetWidth: 62),
                    placed(AutoRoute.neutral, target(AutoRoute.neutral),
                        targetWidth: 64),
                    placed(AutoRoute.shot, hubControl ?? target(AutoRoute.shot),
                        targetWidth: 82,
                        targetHeight: hubControl == null ? 48 : 72),
                    Positioned(
                        left: rotated ? null : 4,
                        right: rotated ? 4 : null,
                        top: height / 2 - 35,
                        child: IgnorePointer(
                            child: RotatedBox(
                                quarterTurns: rotated ? 1 : 3,
                                child: _zoneBadge('DRIVER WALL', accent)))),
                    Positioned(
                        left: rotated ? 8 : null,
                        right: rotated ? null : 8,
                        top: 7,
                        child: IgnorePointer(
                            child: _zoneBadge(
                                'NEUTRAL', const Color(0xFFFFD28A)))),
                  ]),
                ));
          })),
          const SizedBox(height: 7),
          Text(
              path.isEmpty
                  ? 'Choose where the preload is shot. Then tap the places the robot uses.'
                  : '${path.length} recorded actions · arrows show the order of visited areas',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ));

  Widget _zoneBadge(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xE00B111B),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800, color: color)));
}

class _FieldRoutePainter extends CustomPainter {
  final List<String> path;
  final Color accent;
  final bool flipped;
  _FieldRoutePainter(List<String> path, this.accent, this.flipped)
      : path = List.of(path);
  @override
  void paint(Canvas canvas, Size size) {
    Offset point(Offset p) => Offset((flipped ? 1 - p.dx : p.dx) * size.width,
        (flipped ? 1 - p.dy : p.dy) * size.height);
    Offset? previous;
    var neutral = false;
    final line = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    void segment(Offset from, Offset to) {
      if ((from - to).distance < 1) return;
      canvas.drawLine(
          point(from),
          point(to),
          Paint()
            ..color = const Color(0xFF0B111B)
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(point(from), point(to), line);
      final a = point(from);
      final b = point(to);
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      final tip = Offset.lerp(a, b, .65)!;
      for (final delta in [-.55, .55])
        canvas.drawLine(
            tip,
            tip -
                Offset(
                    math.cos(angle + delta) * 8, math.sin(angle + delta) * 8),
            line);
    }

    final labels = <String, int>{};
    for (var i = 0; i < path.length; i++) {
      final action = path[i].replaceFirst('Start ', 'Preload ');
      final p = AutoFieldMap.positions[action];
      if (p == null) continue;
      labels[action] = i + 1;
      if (action == AutoRoute.shot)
        continue; // A shot does not move the robot to the hub.
      if (previous != null) segment(previous, p);
      if (AutoRoute.crossings.contains(action)) {
        neutral = !neutral;
        final exit = Offset(neutral ? .72 : .40, p.dy);
        segment(p, exit);
        previous = exit;
      } else {
        previous = p;
      }
    }
    for (final entry in labels.entries) {
      final at = point(AutoFieldMap.positions[entry.key]!);
      final badge = Offset((at.dx + 35).clamp(11, size.width - 11),
          (at.dy - 26).clamp(11, size.height - 11));
      canvas.drawCircle(badge, 10, Paint()..color = accent);
      final text = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
              text: '${entry.value}',
              style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 10,
                  fontWeight: FontWeight.w900)))
        ..layout();
      text.paint(canvas, badge - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_FieldRoutePainter old) =>
      !listEquals(path, old.path) ||
      accent != old.accent ||
      flipped != old.flipped;
}
