import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../player/player_screen.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/poster_art.dart';

/// Cinematic detail v2: Ken Burns hero with overlaid title block, meta
/// chips, cast avatars and the aurora-bordered "delivery intelligence"
/// panel with a live quality-ladder visualization.
class DetailScreen extends StatelessWidget {
  final Movie movie;
  final AppState app;
  const DetailScreen({super.key, required this.movie, required this.app});

  @override
  Widget build(BuildContext context) {
    final progress = app.progressOf(movie);
    final inList = app.inMyList(movie.id);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.bg,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: _GlassCircleBtn(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  KenBurns(maxScale: 1.07, period: const Duration(seconds: 26), child: BackdropArt(movie: movie, radius: 0)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(.35),
                          Colors.transparent,
                          AppTheme.bg,
                        ],
                        stops: const [0, 0.42, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const PulseDot(color: AppTheme.cyan, size: 5),
                            const SizedBox(width: 7),
                            Text(
                              movie.genres.map((g) => g.toUpperCase()).join('  ·  '),
                              style: const TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 2.4,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.cyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.title,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 32,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            shadows: [Shadow(blurRadius: 22, color: Colors.black45)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList.list(
              children: [
                Text(
                  movie.tagline,
                  style: const TextStyle(color: AppTheme.textMid, fontStyle: FontStyle.italic, fontSize: 14.5, height: 1.4),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _meta(Icons.star_rounded, '${movie.rating}', AppTheme.amber),
                    _meta(Icons.calendar_today_outlined, '${movie.year}', null),
                    _meta(Icons.timer_outlined, movie.isSeries ? 'S${movie.season}:E${movie.episode}' : '${movie.runtimeMin} min', null),
                    _meta(Icons.verified_user_outlined, movie.maturity, null),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(.18), blurRadius: 24)],
                        ),
                        child: FilledButton.icon(
                          onPressed: () => _play(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 26),
                          label: Text(progress > 0.01 ? 'Resume' : 'Play'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GlassCircleBtn(
                      big: true,
                      icon: inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      tint: inList ? AppTheme.cyan : null,
                      onTap: () async {
                        await app.toggleMyList(movie.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(!inList ? 'Added to My List' : 'Removed from My List'),
                          ));
                        }
                      },
                    ),
                  ],
                ),
                if (progress > 0.01 && progress < 0.95) ...[
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHi,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(colors: AppTheme.aurora),
                            boxShadow: [BoxShadow(color: AppTheme.cyan.withOpacity(.6), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% watched — the playhead will be recovered exactly where you left it',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDim),
                  ),
                ],
                const SizedBox(height: 28),
                _SectionHead(title: 'The Story'),
                const SizedBox(height: 10),
                Text(
                  movie.synopsis,
                  style: const TextStyle(height: 1.65, color: Color(0xFFC7D0E2), fontSize: 15),
                ),
                const SizedBox(height: 26),
                _SectionHead(title: 'Cast'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: movie.cast.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final name = movie.cast[i];
                      return SizedBox(
                        width: 64,
                        child: Column(
                          children: [
                            InitialsAvatar(name: name, index: i, size: 48),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMid, height: 1.2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 26),
                _DeliveryPanel(movie: movie, app: app),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: color ?? AppTheme.textMid),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _play(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(movie: movie, app: app),
    ));
  }
}

class _GlassCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool big;
  final Color? tint;
  const _GlassCircleBtn({required this.icon, required this.onTap, this.big = false, this.tint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: big ? 52 : 42,
        height: big ? 52 : 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surface.withOpacity(.85),
          border: Border.all(color: Colors.white.withOpacity(.09)),
        ),
        child: Icon(icon, size: big ? 22 : 19, color: tint ?? AppTheme.textHi),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  const _SectionHead({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}

/// Explains, per-title, how the delivery pipeline treats this stream —
/// now wrapped in the aurora border with a ladder visualization.
class _DeliveryPanel extends StatelessWidget {
  final Movie movie;
  final AppState app;
  const _DeliveryPanel({required this.movie, required this.app});

  @override
  Widget build(BuildContext context) {
    final pack = movie.pack;
    final hosts = pack.urls.map((u) => Uri.parse(u).host).toSet().toList();

    return AppTheme.auroraBorder(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_rounded, size: 17, color: AppTheme.cyan),
              const SizedBox(width: 8),
              const Text('Delivery intelligence', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              const PulseDot(color: AppTheme.green, size: 5),
              const SizedBox(width: 6),
              Text(
                pack.isHls ? 'HLS · LADDER' : 'PROGRESSIVE',
                style: const TextStyle(fontSize: 9.5, letterSpacing: 1.8, color: AppTheme.cyan, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('CDN edges', '${hosts.length} independent host${hosts.length > 1 ? 's' : ''} probed & ranked by latency'),
          _row('Packaging', pack.isHls ? 'Multi-variant HLS — ladder from 240p to 4K' : 'Single-file progressive over HTTP(S)'),
          _row('Resilience', 'Segment retries · mirror failover · position recovery'),
          _row('ABR strategy', 'Buffer + throughput hybrid (BOLA-style) with hysteresis'),
          _row('Preload', 'Manifest warmed pre-play · next episode prefetched at 85%'),
          const SizedBox(height: 14),
          // ── Quality ladder visualization ──
          Text(
            'THE ADAPTIVE LADDER',
            style: AppTheme.kicker.copyWith(fontSize: 8.5, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final t in QualityTier.ladder)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 6 + 44 * (t.bitrate / QualityTier.ladder.last.bitrate),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppTheme.cyan.withOpacity(.75),
                                  AppTheme.indigo.withOpacity(.55),
                                  AppTheme.violet.withOpacity(.4),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t.label,
                            style: const TextStyle(fontSize: 8, color: AppTheme.textDim, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '7 rungs from 240p to 4K — the ABR engine hops to the best rung your link can hold, every 2 seconds.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textDim, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final h in hosts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHi.withOpacity(.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(h, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMid)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                k.toUpperCase(),
                style: const TextStyle(fontSize: 9.5, color: AppTheme.textDim, fontWeight: FontWeight.w800, letterSpacing: 1.1, height: 1.6),
              ),
            ),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFFCBD4E6)))),
          ],
        ),
      );
}
