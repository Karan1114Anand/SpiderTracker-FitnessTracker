/// A level indicator drawn as an orb web: eight spokes, three octagonal
/// rings, and the outer ring filling clockwise as points accumulate.
///
/// It is the app's one Spider-Man motif. Everything around it stays plain.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WebRing extends StatelessWidget {
  const WebRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 84,
    this.caption,
  });

  /// 0 to 1: how far through the current level.
  final double progress;

  /// Centre text, normally the level number.
  final String label;
  final double size;

  /// Small text under [label], e.g. "LEVEL".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _WebPainter(progress.clamp(0.0, 1.0)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (caption != null)
                Text(
                  caption!,
                  style: text.labelSmall?.copyWith(fontSize: size * 0.11),
                ),
              Text(
                label,
                style: text.headlineMedium?.copyWith(
                  fontSize: size * 0.34,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebPainter extends CustomPainter {
  _WebPainter(this.progress);

  final double progress;

  static const int _spokes = 8;

  Path _octagon(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < _spokes; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / _spokes;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2 - 3;

    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SpiderColors.outline;

    for (final f in [0.36, 0.68]) {
      canvas.drawPath(_octagon(c, outer * f), faint);
    }
    for (var i = 0; i < _spokes; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / _spokes;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * outer, faint);
    }

    final outerPath = _octagon(c, outer);
    canvas.drawPath(
      outerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = SpiderColors.outline,
    );

    if (progress > 0) {
      final metric = outerPath.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = SpiderColors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(_WebPainter old) => old.progress != progress;
}
