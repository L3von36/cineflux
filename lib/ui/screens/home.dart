import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../widgets/movie_card.dart';
import '../widgets/poster_art.dart';
import 'detail.dart';

class HomeScreen extends StatelessWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final featured = Catalog.byId('sintel');
    final cw = app.continueWatching();
    final progress = app.progress;

    final rows = <(String, String?, List<Movie>)>[
      ('Continue Watching', null, cw),
      ('For Bigger — the series', 'binge-ready', Catalog.series()),
      ('Animation', null, Catalog.byGenre('Animation')),
      ('Sci-Fi & Fantasy', null, [...Catalog.byGenre('Sci-Fi'), ...Catalog.byGenre('Fantasy')]),
      ('Documentaries', null, [...Catalog.byGenre('Documentary'), ...Catalog.byGenre('Motoring'), ...Catalog.byGenre('Sport')]),
      ('Everything', 'the full catalog', Catalog.all),
    ];

    return RefreshIndicator(
      onRefresh: app.refresh,
      color: AppTheme.cyan,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Billboard(movie: featured, app: app),
          for (final (title, sub, movies) in rows) ...[
            if (movies.isNotEmpty)
              CatalogRow(
                title: title,
                subtitle: sub,
                movies: movies,
                progressMap: progress,
                onTap: (m) => _openDetail(context, m),
              ),
          ],
          const _EngineeringStrip(),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Movie m) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => DetailScreen(movie: m, app: app),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .04), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ));
  }
}

/// Hero billboard — ambient glow bleeds from the artwork into the page.
class _Billboard extends StatelessWidget {
  final Movie movie;
  final AppState app;
  const _Billboard({required this.movie, required this.app});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 700;
    final h = wide ? 340.0 : 400.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropArt(movie: movie, radius: 0),
              // Readability scrim.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black.withOpacity(.55), Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 32 : 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 430 : 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withOpacity(.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cyan.withOpacity(.4)),
                        ),
                        child: Text(
                          'FEATURED · MULTI-CDN STREAM',
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 2.4,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.cyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.tagline,
                        style: const TextStyle(
                          color: AppTheme.textMid,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${movie.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 12),
                          Text('${movie.year}', style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                          const SizedBox(width: 12),
                          Text(movie.maturity, style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                          const SizedBox(width: 12),
                          Text('${movie.runtimeMin} min', style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DetailScreen(movie: movie, app: app),
                              ));
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 26),
                            label: const Text('Play'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DetailScreen(movie: movie, app: app),
                              ));
                            },
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
}

/// The subtle flex: a strip that tells the user what's powering playback.
class _EngineeringStrip extends StatelessWidget {
  const _EngineeringStrip();

  @override
  Widget build(BuildContext context) {
    final chips = [
      (Icons.bolt_rounded, 'Adaptive Bitrate'),
      (Icons.dns_rounded, 'Multi-CDN'),
      (Icons.speed_rounded, 'EWMA Meter'),
      (Icons.healing_rounded, 'Self-Healing'),
      (Icons.download_for_offline_outlined, 'Preload Pipeline'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POWERING YOUR STREAM',
            style: TextStyle(fontSize: 10.5, letterSpacing: 3, color: AppTheme.textMid, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label) in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: AppTheme.cyan),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMid)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
