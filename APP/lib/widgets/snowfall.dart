import 'dart:math' as math;
import 'package:flutter/material.dart';

class Snowfall extends StatefulWidget {
  final Widget child;
  const Snowfall({super.key, required this.child});

  @override
  State<Snowfall> createState() => _SnowfallState();
}

class _SnowfallState extends State<Snowfall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snow =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _snow.stop();
    } else {
      _snow.repeat();
    }
  }

  @override
  void dispose() {
    _snow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(painter: _SnowPainter(_snow)),
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ]);
}

class _SnowPainter extends CustomPainter {
  final Animation<double> animation;
  _SnowPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1;
    for (var i = 0; i < 28; i++) {
      final progress = animation.value;
      final x =
          ((i * 0.618034 + math.sin(progress * math.pi * 2 + i) * 0.025) % 1) *
              size.width;
      final y =
          ((i * 0.381966 + progress * (1 + i % 3 * 0.2)) % 1) * size.height;
      final radius = 2.5 + i % 4;
      paint.color =
          const Color(0xFFC8E4FF).withValues(alpha: 0.08 + i % 3 * 0.035);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 2 + i);
      for (var arm = 0; arm < 6; arm++) {
        canvas.drawLine(Offset.zero, Offset(0, radius), paint);
        canvas.drawLine(Offset(0, radius * 0.6),
            Offset(radius * 0.28, radius * 0.35), paint);
        canvas.drawLine(Offset(0, radius * 0.6),
            Offset(-radius * 0.28, radius * 0.35), paint);
        canvas.rotate(math.pi / 3);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SnowPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
