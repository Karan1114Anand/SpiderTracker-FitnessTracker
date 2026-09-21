/// Today's five habits as a web: one spoke each for workout, food, water,
/// sleep and run. The red shape fills outward as points are earned, so the
/// weakest habit is the shortest spoke. Points earned sit in the middle.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RadarAxis {
  const RadarAxis(this.label, this.fraction);

  final String label;

  /// 0 to 1: how much of this habit's daily points are earned.
  final double fraction;
}

class WebRadar extends StatelessWidget {
  const WebRadar({
    super.key,
    required this.axes,
    required this.points,
    required this.maxPoints,
  });

  final List<RadarAxis> axes;
  final int points;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Skip the draw-in when the system asks for reduced motion.
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label:
          'Today: $points of $maxPoints points. '
          '${axes.map((a) => '${a.label} ${(a.fraction * 100).round()} percent').join(', ')}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$points', style: text.displayLarge),
              const SizedBox(width: SpiderSpace.sm),
              Text('of $maxPoints points today', style: text.bodyMedium),
            ],
          ),
          AspectRatio(
            aspectRatio: 1.15,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, grow, _) => CustomPaint(
                painter: _RadarPainter(
                  axes: axes,
                  grow: grow,
                  labelStyle: text.bodySmall!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axes,
    required this.grow,
    required this.labelStyle,
  });

  final List<RadarAxis> axes;
  final double grow;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 34; // room for labels

    Offset at(int i, double f) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return c + Offset(math.cos(a), math.sin(a)) * r * f;
    }

    Path ring(double f) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final o = at(i, f);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SpiderColors.outline;

    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawPath(ring(f), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, at(i, 1), grid);
    }

    // The filled shape. A small floor keeps an empty day from vanishing.
    final shape = Path();
    for (var i = 0; i < n; i++) {
      final f = (axes[i].fraction.clamp(0.0, 1.0) * grow).clamp(0.04, 1.0);
      final o = at(i, f);
      i == 0 ? shape.moveTo(o.dx, o.dy) : shape.lineTo(o.dx, o.dy);
    }
    shape.close();
    canvas.drawPath(
      shape,
      Paint()..color = SpiderColors.accent.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = SpiderColors.accent,
    );
    for (var i = 0; i < n; i++) {
      final f = (axes[i].fraction.clamp(0.0, 1.0) * grow).clamp(0.04, 1.0);
      canvas.drawCircle(at(i, f), 4, Paint()..color = SpiderColors.accent);
    }

    // Axis labels, just outside the outer ring.
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(text: axes[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = at(i, 1.0);
      final dir = (p - c) / (p - c).distance;
      final anchor = p + dir * 16;
      canvas.save();
      canvas.translate(
        anchor.dx - tp.width / 2 + dir.dx * tp.width / 2,
        anchor.dy - tp.height / 2 + dir.dy * tp.height / 2,
      );
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.grow != grow || old.axes != axes;
}
