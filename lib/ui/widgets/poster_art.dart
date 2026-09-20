import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// Cinematic artwork generated 100% locally — a layered gradient "mesh",
/// film grain, glow bloom and bold typography. Zero image fetches: the
/// poster appears as fast as the frame can paint, even on 2G. The palette
/// is derived from the title itself, so each film owns its identity.
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
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          // Aurora bloom.
          CustomPaint(painter: _BloomPainter(palette: p, seed: movie.id.hashCode)),
          // Film grain.
          CustomPaint(painter: _GrainPainter(seed: movie.id.hashCode)),
          // Vignette for typography contrast.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.65)],
                stops: const [0.45, 1],
              ),
            ),
          ),
          if (showTitle)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CINEFLUX',
                    style: TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 3.2,
                      color: Colors.white.withOpacity(.75),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    movie.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      shadows: [Shadow(blurRadius: 18, color: Colors.black45)],
                    ),
                  ),
                  const SizedBox(height: 6),
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

/// Wide 16:9 backdrop variant used by billboards and the detail hero.
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
                    style: TextStyle(
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

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
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
    for (var i = 0; i < 3; i++) {
      final color = [palette.b, palette.c, palette.a][i].withOpacity(.38 - i * .07);
      final center = Offset(
        size.width * (0.15 + rng.nextDouble() * 0.7),
        size.height * (0.1 + rng.nextDouble() * 0.6),
      );
      final radius = size.shortestSide * (0.45 + rng.nextDouble() * 0.45);
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

