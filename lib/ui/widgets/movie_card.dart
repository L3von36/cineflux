import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import 'poster_art.dart';

/// Poster card v2 — aurora-lit frames: gradient progress rail, hover lift
/// with glow + play reveal on pointer devices, generated artwork.
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
    final prog = widget.progress?.clamp(0.0, 1.0).toDouble();

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: _hover ? 1.05 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: w,
            child: AspectRatio(
              aspectRatio: widget.aspect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hover ? AppTheme.cyan.withOpacity(.65) : Colors.white.withOpacity(.07),
                    width: _hover ? 1.2 : 1,
                  ),
                  boxShadow: _hover
                      ? [
                          BoxShadow(
                            color: AppTheme.cyan.withOpacity(.22),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PosterArt(movie: widget.movie, radius: 0),
                      // Hover play reveal.
                      AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          color: AppTheme.bg.withOpacity(.45),
                          alignment: Alignment.center,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(.92),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.cyan.withOpacity(.5),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      // Continue-watching progress rail.
                      if (prog != null && prog > 0.01)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 9,
                          child: Stack(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.22),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: prog,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: const LinearGradient(
                                      colors: AppTheme.aurora,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.cyan.withOpacity(.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide 16:9 continue-watching card: backdrop art, title chip, glowing
/// progress rail and a hover play affordance.
class ContinueCard extends StatefulWidget {
  final Movie movie;
  final double progress;
  final VoidCallback onTap;
  const ContinueCard({
    super.key,
    required this.movie,
    required this.progress,
    required this.onTap,
  });

  @override
  State<ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<ContinueCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final prog = widget.progress.clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: _hover ? 1.035 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 238,
            margin: const EdgeInsets.only(right: 12),
            child: AspectRatio(
              aspectRatio: 16 / 8.4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hover ? AppTheme.cyan.withOpacity(.6) : Colors.white.withOpacity(.07),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_hover ? .55 : .4),
                      blurRadius: _hover ? 24 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BackdropArt(movie: widget.movie, radius: 0, showMeta: false),
                      // Bottom readability gradient.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(.78)],
                            stops: const [0.45, 1],
                          ),
                        ),
                      ),
                      // Resume affordance.
                      AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          alignment: Alignment.center,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(.92),
                              boxShadow: [
                                BoxShadow(color: AppTheme.cyan.withOpacity(.5), blurRadius: 20),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 28),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${(prog * 100).toStringAsFixed(0)}% watched · resume',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMid,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Stack(
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.22),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: prog,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: const LinearGradient(colors: AppTheme.aurora),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.cyan.withOpacity(.8),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal, snap-scrolling row with an aurora-tick header — the
/// Netflix row pattern, CineFlux styled. Supports portrait posters and
/// wide continue-watching cards.
class CatalogRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Movie> movies;
  final Map<String, double>? progressMap;
  final void Function(Movie) onTap;
  final EdgeInsetsGeometry padding;
  final bool landscape;
  final bool stagger;
  const CatalogRow({
    super.key,
    required this.title,
    required this.movies,
    required this.onTap,
    this.subtitle,
    this.progressMap,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.landscape = false,
    this.stagger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();
    final rowHeight = landscape ? 165.0 : 148 / (2 / 3) + 6;

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
                Container(
                  width: 4,
                  height: 15,
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: AppTheme.aurora,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Text(title, style: AppTheme.sectionTitle),
                const SizedBox(width: 8),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textDim,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: rowHeight,
            child: landscape
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: movies.length,
                    itemBuilder: (context, i) {
                      final m = movies[i];
                      return ContinueCard(
                        movie: m,
                        progress: progressMap?[m.id] ?? 0,
                        onTap: () => onTap(m),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: movies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final m = movies[i];
                      final card = MovieCard(
                        movie: m,
                        onTap: () => onTap(m),
                        progress: progressMap?[m.id],
                      );
                      return stagger ? _StaggerWrap(index: i, child: card) : card;
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StaggerWrap extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerWrap({required this.index, required this.child});

  @override
  State<_StaggerWrap> createState() => _StaggerWrapState();
}

class _StaggerWrapState extends State<_StaggerWrap> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 + 45 * widget.index.clamp(0, 9)), () {
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
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(18 * (1 - _a.value), 0),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
