import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/movie_card.dart';
import '../widgets/poster_art.dart';
import 'detail.dart';

class HomeScreen extends StatelessWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night session';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final featured = Catalog.byId('sintel');
    final cw = app.continueWatching();
    final progress = app.progress;
    final today = _days[DateTime.now().weekday - 1];

    final rows = <(String, String?, List<Movie>)>[
      ('Continue Watching', 'pick up where you left off', cw),
      ('For Bigger — the series', 'binge-ready', Catalog.series()),
      ('Animation', 'hand-crafted worlds', Catalog.byGenre('Animation')),
      ('Sci-Fi & Fantasy', null, [...Catalog.byGenre('Sci-Fi'), ...Catalog.byGenre('Fantasy')]),
      ('Documentaries', null, [...Catalog.byGenre('Documentary'), ...Catalog.byGenre('Motoring'), ...Catalog.byGenre('Sport')]),
      ('Everything', 'the full catalog', Catalog.all),
    ];

    return RefreshIndicator(
      onRefresh: app.refresh,
      color: AppTheme.cyan,
      backgroundColor: AppTheme.surface,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
            child: StaggerIn(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.4),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '· $today',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StaggerIn(index: 1, child: _Billboard(movie: featured, app: app)),
          for (var r = 0; r < rows.length; r++)
            if (rows[r].$3.isNotEmpty)
              StaggerIn(
                index: r + 2,
                child: CatalogRow(
                  title: rows[r].$1,
                  subtitle: rows[r].$2,
                  movies: rows[r].$3,
                  progressMap: progress,
                  landscape: r == 0,
                  stagger: r > 0,
                  onTap: (m) => _openDetail(context, m),
                ),
              ),
          const StaggerIn(index: 8, child: _EngineeringStrip()),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Movie m) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => DetailScreen(movie: m, app: app),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .045), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ));
  }
}

/// Hero billboard v2 — Ken Burns drift over the generated art, a live
/// multi-CDN pulse badge, editorial typography and glowing actions.
class _Billboard extends StatelessWidget {
  final Movie movie;
  final AppState app;
  const _Billboard({required this.movie, required this.app});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 700;
    final h = wide ? 360.0 : 430.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Drifting artwork.
              KenBurns(maxScale: 1.08, child: BackdropArt(movie: movie, radius: 0)),
              // Readability scrims.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black.withOpacity(.62), Colors.transparent],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(.18), Colors.black.withOpacity(.55)],
                    stops: const [0, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 34 : 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 440 : 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live badge.
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bg.withOpacity(.55),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppTheme.cyan.withOpacity(.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PulseDot(color: AppTheme.green, size: 6),
                            const SizedBox(width: 7),
                            Text(
                              'FEATURED · MULTI-CDN STREAM',
                              style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 2.4,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.cyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 36,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          shadows: [Shadow(blurRadius: 24, color: Colors.black45)],
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        movie.tagline,
                        style: const TextStyle(
                          color: AppTheme.textMid,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${movie.rating}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          _dot(),
                          Text('${movie.year}', style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                          _dot(),
                          Text(movie.maturity, style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                          _dot(),
                          Text('${movie.runtimeMin} min', style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.white.withOpacity(.22), blurRadius: 26),
                              ],
                            ),
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => DetailScreen(movie: movie, app: app),
                                ));
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 26),
                              label: const Text('Play'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DetailScreen(movie: movie, app: app),
                              ));
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.bg.withOpacity(.4),
                            ),
                            icon: const Icon(Icons.info_outline_rounded, size: 18),
                            label: const Text('Details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.textDim.withOpacity(.8),
          ),
        ),
      );
}

/// The subtle flex v2 — a glass panel that tells you what's powering
/// playback, with aurora-lit chips.
class _EngineeringStrip extends StatelessWidget {
  const _EngineeringStrip();

  @override
  Widget build(BuildContext context) {
    final chips = [
      (Icons.bolt_rounded, 'Adaptive Bitrate', 'ABR hops the ladder for you'),
      (Icons.dns_rounded, 'Multi-CDN', 'probes & steers between edges'),
      (Icons.speed_rounded, 'EWMA Meter', 'live bandwidth estimation'),
      (Icons.healing_rounded, 'Self-Healing', 'failover without a rewind'),
      (Icons.download_for_offline_outlined, 'Preload Pipeline', 'next episode, already warm'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glass(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PulseDot(color: AppTheme.cyan, size: 6),
                const SizedBox(width: 8),
                Text(
                  'POWERING YOUR STREAM',
                  style: AppTheme.kicker.copyWith(color: AppTheme.textMid, letterSpacing: 2.6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label, sub) in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHi.withOpacity(.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(.06)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(colors: [
                              AppTheme.cyan.withOpacity(.18),
                              AppTheme.violet.withOpacity(.18),
                            ]),
                          ),
                          child: Icon(icon, size: 15, color: AppTheme.cyan),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(sub, style: const TextStyle(fontSize: 9.5, color: AppTheme.textDim)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
