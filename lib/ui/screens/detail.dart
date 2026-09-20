import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../player/player_screen.dart';
import '../widgets/poster_art.dart';

/// Cinematic detail screen: hero backdrop with ambient glow, meta, actions
/// and a "delivery intelligence" panel that explains how this title travels
/// to the device.
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
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.bg,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropArt(movie: movie, radius: 0),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(.25),
                          Colors.transparent,
                          AppTheme.bg,
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            sliver: SliverList.list(
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.05),
                ),
                const SizedBox(height: 6),
                Text(
                  movie.tagline,
                  style: const TextStyle(color: AppTheme.textMid, fontStyle: FontStyle.italic, fontSize: 14),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _meta(Icons.star_rounded, '${movie.rating}', AppTheme.amber),
                    _meta(Icons.calendar_today_outlined, '${movie.year}', null),
                    _meta(Icons.timer_outlined, movie.isSeries ? 'S${movie.season}:E${movie.episode}' : '${movie.runtimeMin} min', null),
                    _meta(Icons.verified_user_outlined, movie.maturity, null),
                    for (final g in movie.genres) _meta(Icons.category_outlined, g, null),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _play(context, resume: true),
                        icon: const Icon(Icons.play_arrow_rounded, size: 26),
                        label: Text(progress > 0.01 ? 'Resume' : 'Play'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      onPressed: () async {
                        await app.toggleMyList(movie.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(!inList ? 'Added to My List' : 'Removed from My List'),
                          ));
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceHi,
                        side: const BorderSide(color: AppTheme.line),
                      ),
                      icon: Icon(
                        inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: inList ? AppTheme.cyan : AppTheme.textHi,
                      ),
                    ),
                  ],
                ),
                if (progress > 0.01 && progress < 0.95) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppTheme.surfaceHi,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.cyan),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${(progress * 100).toStringAsFixed(0)}% watched — the playhead will be recovered exactly where you left it',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                ],
                const SizedBox(height: 24),
                const Text('Story', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  movie.synopsis,
                  style: const TextStyle(height: 1.55, color: Color(0xFFC3CBD9), fontSize: 14.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cast: ${movie.cast.join(', ')}',
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? AppTheme.textMid),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _play(BuildContext context, {required bool resume}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(movie: movie, app: app),
    ));
  }
}

/// Explains, per-title, how the delivery pipeline treats this stream.
class _DeliveryPanel extends StatelessWidget {
  final Movie movie;
  final AppState app;
  const _DeliveryPanel({required this.movie, required this.app});

  @override
  Widget build(BuildContext context) {
    final pack = movie.pack;
    final hosts = pack.urls.map((u) => Uri.parse(u).host).toSet().toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_rounded, size: 17, color: AppTheme.cyan),
              const SizedBox(width: 8),
              const Text('Delivery intelligence', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text(
                pack.isHls ? 'HLS · ADAPTIVE LADDER' : 'PROGRESSIVE',
                style: const TextStyle(fontSize: 10, letterSpacing: 1.6, color: AppTheme.cyan, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('CDN endpoints', '${hosts.length} independent host${hosts.length > 1 ? 's' : ''} probed & ranked by latency'),
          _row('Packaging', pack.isHls ? 'Multi-variant HLS — quality ladder from 240p up' : 'Single-file progressive over HTTP(S)'),
          _row('Resilience', 'Segment retries · mirror failover · position recovery'),
          _row('ABR strategy', 'Buffer + throughput hybrid (BOLA-style) with hysteresis'),
          _row('Preload', 'Manifest warmed pre-play · next episode prefetched at 85%'),
          const SizedBox(height: 10),
          for (final h in hosts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.lan_rounded, size: 13, color: AppTheme.textMid),
                  const SizedBox(width: 7),
                  Expanded(child: Text(h, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMid))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: Text(k, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMid, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(v, style: const TextStyle(fontSize: 12.5, height: 1.35))),
          ],
        ),
      );
}
