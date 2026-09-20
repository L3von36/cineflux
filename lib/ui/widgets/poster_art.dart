import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// ── GENERATIVE ARTWORK v2 ────────────────────────────────────────────────
/// Cinematic art painted 100% locally: layered aurora mesh, bloom lights,
/// a diagonal sheen, film grain and editorial typography. Zero image
/// fetches — the poster paints as fast as the frame, even on 2G. The
/// palette is derived from the title itself, so every film owns its look.
class PosterArt extends StatelessWidget {
  final Movie movie;
  final double radius;
  final bool showTitle;
  const PosterArt({
    super.key,
    required this.movie,
    this.radius = 14,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = movie.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base mesh gradient.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.b, p.a, p.c],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
          // Aurora blooms.
          CustomPaint(painter: _BloomPainter(palette: p, seed: movie.id.hashCode)),
          // Diagonal sheen — a static glass light sweep.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.centerLeft,
                colors: [Colors.white.withOpacity(.08), Colors.white.withOpacity(0)],
                stops: const [0, 0.55],
              ),
            ),
          ),
          // Film grain.
          CustomPaint(painter: _GrainPainter(seed: movie.id.hashCode)),
          // Vignette for typography contrast.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.68)],
                stops: const [0.42, 1],
              ),
            ),
          ),
          if (showTitle)
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppTheme.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'CINEFLUX',
                        style: TextStyle(
                          fontSize: 8.5,
                          letterSpacing: 3.4,
                          color: Colors.white.withOpacity(.8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    movie.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.06,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      shadows: [Shadow(blurRadius: 20, color: Colors.black54)],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _MiniPill(text: '★ ${movie.rating}'),
                      const SizedBox(width: 5),
                      _MiniPill(text: movie.maturity),
                      if (movie.isSeries) ...[
                        const SizedBox(width: 5),
                        _MiniPill(text: 'S${movie.season}:E${movie.episode}'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Wide 16:9 backdrop variant used by billboards, detail heroes and the
/// continue-watching rail.
class BackdropArt extends StatelessWidget {
  final Movie movie;
  final double radius;
  final bool showMeta;
  const BackdropArt({
    super.key,
    required this.movie,
    this.radius = 18,
    this.showMeta = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = movie.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.bottomRight,
                colors: [p.a, p.c, p.b],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
          CustomPaint(painter: _BloomPainter(palette: p, seed: movie.id.hashCode, wide: true)),
          CustomPaint(painter: _GrainPainter(seed: movie.id.hashCode, density: 0.5)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.72)],
                stops: const [0.35, 1],
              ),
            ),
          ),
          if (showMeta)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    movie.isSeries ? movie.seriesName! : movie.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 4,
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Slow cinematic pan/zoom over any artwork. The child overflows its box
/// and is clipped, so the frame is always filled — no edge vignetting.
class KenBurns extends StatefulWidget {
  final Widget child;
  final double maxScale;
  final Duration period;
  const KenBurns({
    super.key,
    required this.child,
    this.maxScale = 1.09,
    this.period = const Duration(seconds: 24),
  });

  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_c.value);
            return Transform.translate(
              offset: Offset((t - .5) * 8, (t - .5) * -6),
              child: Transform.scale(scale: 1 + (widget.maxScale - 1) * t, child: child),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

/// Soft aurora blooms — the "ambient light" the app is known for.
class _BloomPainter extends CustomPainter {
  final Palette palette;
  final int seed;
  final bool wide;
  _BloomPainter({required this.palette, required this.seed, this.wide = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    for (var i = 0; i < 4; i++) {
      final color = [palette.b, palette.c, palette.a, Colors.white][i]
          .withOpacity(i == 3 ? .10 : .36 - i * .06);
      final center = Offset(
        size.width * (0.12 + rng.nextDouble() * 0.76),
        size.height * (0.08 + rng.nextDouble() * 0.62),
      );
      final radius = size.shortestSide * (0.42 + rng.nextDouble() * 0.5);
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color, color.withOpacity(0)],
        );
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BloomPainter old) => old.seed != seed;
}

/// Film grain — thousands of alpha dots, seeded per title.
class _GrainPainter extends CustomPainter {
  final int seed;
  final double density;
  _GrainPainter({required this.seed, this.density = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed ^ 0xBEEF);
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (size.width * size.height / 90 * density).clamp(120, 900).toInt();
    for (var i = 0; i < count; i++) {
      final o = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.05);
      canvas.drawCircle(o, rng.nextDouble() * 0.9 + 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.seed != seed;
}
