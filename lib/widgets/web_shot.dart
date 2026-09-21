/// The web-shot effect: a strand fires from the corner of the screen to
/// the thing you just tapped and lands as a small web. About half a second,
/// no blocking, and the sound goes with it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sfx.dart';
import '../theme/app_theme.dart';

abstract final class WebFx {
  /// Shoots a web from the lower-right corner to the centre of [context]'s
  /// widget (or to [to], in global coordinates, when given).
  static void shoot(BuildContext context, {Offset? to}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final screen = MediaQuery.sizeOf(context);
    Offset target;
    if (to != null) {
      target = to;
    } else {
      final box = context.findRenderObject();
      target = box is RenderBox && box.hasSize
          ? box.localToGlobal(box.size.center(Offset.zero))
          : screen.center(Offset.zero);
    }
    final from = Offset(screen.width * 0.9, screen.height * 0.96);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          _WebShot(from: from, to: target, onDone: () => entry.remove()),
    );
    overlay.insert(entry);
    HapticFeedback.lightImpact();
    Sfx.thwip();
  }
}

class _WebShot extends StatefulWidget {
  const _WebShot({required this.from, required this.to, required this.onDone});

  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  @override
  State<_WebShot> createState() => _WebShotState();
}

class _WebShotState extends State<_WebShot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ShotPainter(_c.value, widget.from, widget.to),
        ),
      ),
    );
  }
}

class _ShotPainter extends CustomPainter {
  _ShotPainter(this.t, this.from, this.to);

  final double t;
  final Offset from;
  final Offset to;

  static const double _shootEnd = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    // A slight arc so the strand reads as thrown, not ruled.
    final mid = Offset.lerp(from, to, 0.5)!;
    final control = mid + Offset(0, -(from - to).distance * 0.12);

    Offset at(double u) {
      final a = Offset.lerp(from, control, u)!;
      final b = Offset.lerp(control, to, u)!;
      return Offset.lerp(a, b, u)!;
    }

    // Phase 1: the strand extends to the target, then fades.
    final shoot = (t / _shootEnd).clamp(0.0, 1.0);
    final fade = t < _shootEnd
        ? 1.0
        : (1 - (t - _shootEnd) / 0.35).clamp(0.0, 1.0);
    if (fade > 0) {
      final path = Path()..moveTo(from.dx, from.dy);
      const steps = 24;
      for (var i = 1; i <= steps; i++) {
        final p = at(shoot * i / steps);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = SpiderColors.textPrimary.withValues(alpha: 0.85 * fade),
      );
    }

    // Phase 2: a small web blooms where it landed.
    if (t > _shootEnd - 0.04) {
      final u = ((t - (_shootEnd - 0.04)) / (1 - (_shootEnd - 0.04))).clamp(
        0.0,
        1.0,
      );
      final grow = Curves.easeOutCubic.transform(math.min(u * 1.6, 1.0));
      final alpha = (1 - u).clamp(0.0, 1.0);
      final r = 6 + 30 * grow;
      final web = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = SpiderColors.accent.withValues(alpha: alpha);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(to, to + Offset(math.cos(a), math.sin(a)) * r, web);
      }
      for (final f in [0.5, 1.0]) {
        final ring = Path();
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final p = to + Offset(math.cos(a), math.sin(a)) * r * f;
          i == 0 ? ring.moveTo(p.dx, p.dy) : ring.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(ring..close(), web);
      }
    }
  }

  @override
  bool shouldRepaint(_ShotPainter old) => old.t != t;
}
