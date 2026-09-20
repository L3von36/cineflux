import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import 'poster_art.dart';

/// Poster card used across rows & grids — hover lift on pointer devices,
/// continue-watching progress bar, generated artwork.
class MovieCard extends StatefulWidget {
  final Movie movie;
  final double width;
  final double aspect; // width/height
  final double? progress; // 0..1
  final VoidCallback onTap;
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.width = 148,
    this.aspect = 2 / 3,
    this.progress,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w / widget.aspect;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: _hover ? 1.045 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: w,
                      height: h,
                      child: PosterArt(movie: widget.movie),
                    ),
                    if (widget.progress != null && widget.progress! > 0.01)
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: widget.progress!.clamp(0, 1),
                            minHeight: 3.5,
                            backgroundColor: Colors.white.withOpacity(.25),
                            valueColor: const AlwaysStoppedAnimation(AppTheme.cyan),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal, snap-scrolling row with a header — the Netflix row pattern.
class CatalogRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Movie> movies;
  final Map<String, double>? progressMap;
  final void Function(Movie) onTap;
  final EdgeInsetsGeometry padding;
  const CatalogRow({
    super.key,
    required this.title,
    required this.movies,
    required this.onTap,
    this.subtitle,
    this.progressMap,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148 / (2 / 3) + 8,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final m = movies[i];
                return MovieCard(
                  movie: m,
                  onTap: () => onTap(m),
                  progress: progressMap?[m.id],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
