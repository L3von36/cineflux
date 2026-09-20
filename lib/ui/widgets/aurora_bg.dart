import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// ── AURORA FX KIT ───────────────────────────────────────────────────────
/// Shared motion & atmosphere primitives used across the app.

/// Slow-drifting ambient aurora. Painted as three huge soft radial blobs
/// orbiting on sine paths behind a vignette — the "theater light" wash.
/// Wrapped in a RepaintBoundary so only this layer repaints each tick.
class AuroraBackdrop extends StatefulWidget {
  final double intensity;
  const AuroraBackdrop({super.key, this.intensity = 1});

  @override
  State<AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<AuroraBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _AuroraPainter(t: _c.value, intensity: widget.intensity),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final double intensity;
  _AuroraPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      (color: AppTheme.cyan, base: const Offset(0.18, 0.05), phase: 0.0, speed: 1.0, r: 0.62),
      (color: AppTheme.indigo, base: const Offset(0.85, 0.25), phase: 2.1, speed: 0.8, r: 0.70),
      (color: AppTheme.violet, base: const Offset(0.45, 0.85), phase: 4.2, speed: 0.6, r: 0.66),
    ];
    for (final b in blobs) {
      final cx = size.width * (b.base.dx + 0.06 * math.sin(t * 2 * math.pi * b.speed + b.phase));
      final cy = size.height * (b.base.dy + 0.05 * math.cos(t * 2 * math.pi * b.speed + b.phase));
      final radius = size.longestSide * b.r;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [b.color.withOpacity(.055 * intensity), b.color.withOpacity(0)],
        );
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.intensity != intensity;
}

/// A live status dot with a radiating pulse — used on kickers & badges.
class PulseDot extends StatefulWidget {
  final double size;
  final Color color;
  const PulseDot({super.key, this.size = 7, this.color = AppTheme.green});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return SizedBox(
          width: s * 2.6,
          height: s * 2.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s + s * 1.6 * t,
                height: s + s * 1.6 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity((1 - t) * .45),
                ),
              ),
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One-shot staggered entrance: fades + slides up, delayed by [index].
class StaggerIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Offset from;
  final int baseMs;
  const StaggerIn({
    super.key,
    required this.child,
    this.index = 0,
    this.from = const Offset(0, 0.16),
    this.baseMs = 0,
  });

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = widget.baseMs + 65 * widget.index.clamp(0, 8);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) {
        final t = _a.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(widget.from.dx * (1 - t) * 24, widget.from.dy * (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Aurora sweep spinner — the app's signature loading ring.
class AuroraSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  const AuroraSpinner({super.key, this.size = 46, this.strokeWidth = 3.4});

  @override
  State<AuroraSpinner> createState() => _AuroraSpinnerState();
}

class _AuroraSpinnerState extends State<AuroraSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _RingPainter(t: _c.value, strokeWidth: widget.strokeWidth),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final double strokeWidth;
  _RingPainter({required this.t, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [Color(0x002DD9FE), AppTheme.cyan, AppTheme.indigo, AppTheme.violet],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, 0, 2 * math.pi * 0.82, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// Small circular avatar with generated gradient + initials (cast & crew).
class InitialsAvatar extends StatelessWidget {
  final String name;
  final int index;
  final double size;
  const InitialsAvatar({super.key, required this.name, this.index = 0, this.size = 46});

  @override
  Widget build(BuildContext context) {
    const pool = [AppTheme.cyan, AppTheme.indigo, AppTheme.violet, AppTheme.amber, AppTheme.green];
    final c = pool[index % pool.length];
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = (parts.isNotEmpty ? parts.first[0] : '?') +
        (parts.length > 1 ? parts.last[0] : '');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [c.withOpacity(.85), c.withOpacity(.35)]),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppTheme.bg,
          fontWeight: FontWeight.w900,
          fontSize: size * .36,
          letterSpacing: .5,
        ),
      ),
    );
  }
}
