import 'models.dart';

/// CineFlux catalog.
///
/// Every stream below is a *real, publicly reachable* stream on a *different
/// CDN host* — exactly the multi-CDN topology the big services use. Mirrors
/// give the CDN selector genuine hosts to probe and fail over between.
///
///   mux.test-streams          → Mux edge (US)
///   bitdash-a.akamaihd.net    → Akamai
///   devstreaming-cdn.apple.com→ Apple CDN
///   demo.unified-streaming.com → Unified Streaming origin
///   commondatastorage.googleapis.com → Google Cloud Storage
class Catalog {
  Catalog._();

  static const bpp = Palette(Color(0xFF0F766E), Color(0xFF22D3EE), Color(0xFF134E4A));
  static const sintelP = Palette(Color(0xFF7C2D12), Color(0xFFF59E0B), Color(0xFF431407));
  static const tosP = Palette(Color(0xFF1E3A8A), Color(0xFF60A5FA), Color(0xFF172554));
  static const bipP = Palette(Color(0xFF4C1D95), Color(0xFFA78BFA), Color(0xFF2E1065));
  static const blazeP = Palette(Color(0xFF7F1D1D), Color(0xFFF87171), Color(0xFF450A0A));
  static const escapeP = Palette(Color(0xFF064E3B), Color(0xFF34D399), Color(0xFF022C22));
  static const funP = Palette(Color(0xFF831843), Color(0xFFF472B6), Color(0xFF500724));
  static const joyP = Palette(Color(0xFF713F12), Color(0xFFFACC15), Color(0xFF422006));
  static const dreamP = Palette(Color(0xFF312E81), Color(0xFF818CF8), Color(0xFF1E1B4B));
  static const bullP = Palette(Color(0xFF3F0F0F), Color(0xFFDC2626), Color(0xFF1C0505));
  static const grandP = Palette(Color(0xFF0C4A6E), Color(0xFF38BDF8), Color(0xFF082F49));

  static const gcs = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample';

  static final List<Movie> all = [
    const Movie(
      id: 'bbb',
      title: 'Big Buck Bunny',
      tagline: 'A gentle giant. A precise revenge.',
      synopsis:
          'A big rabbit with a heart of gold and a grudge against three rowdy '
          'rodents. Blender Foundation\u2019s open-movie classic, delivered here as a '
          'multi-variant HLS stream with six quality renditions across two CDNs — '
          'the same ladder-based packaging Netflix uses.',
      year: 2008,
      rating: 4.6,
      runtimeMin: 10,
      maturity: 'PG',
      genres: ['Animation', 'Comedy', 'Family'],
      cast: ['Blender Foundation', 'Sacha Goedegebure', 'Andy Goralczyk'],
      palette: bpp,
      pack: StreamPack(
        primary: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        isHls: true,
        mirrors: [
          'https://test-streams.mux.dev/pts_shift/master.m3u8',
        ],
      ),
    ),
    const Movie(
      id: 'sintel',
      title: 'Sintel',
      tagline: 'A lone warrior. A dragon\u2019s promise.',
      synopsis:
          'A lonely young woman searches for the dragon companion she lost, '
          'travelling across deserts and mountains. Streamed from Akamai\u2019s edge '
          'as a full multi-bitrate HLS ladder — with the Unified Streaming '
          'platform as the failover mirror if Akamai misbehaves.',
      year: 2010,
      rating: 4.8,
      runtimeMin: 15,
      maturity: 'PG-13',
      genres: ['Fantasy', 'Adventure', 'Animation'],
      cast: ['Halina Reijn', 'Thom Hoffman'],
      palette: sintelP,
      pack: StreamPack(
        primary: 'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8',
        isHls: true,
        mirrors: [
          'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
        ],
      ),
    ),
    const Movie(
      id: 'tos',
      title: 'Tears of Steel',
      tagline: 'Amsterdam. Robots. One last chance.',
      synopsis:
          'A group of warriors and scientists gather at the Oude Kerk to stage '
          'a crucial event from the past, in a desperate attempt to rescue the '
          'world from destructive robots. Delivered via an origin-packaged HLS '
          'ladder with mirror redundancy on a second CDN.',
      year: 2012,
      rating: 4.4,
      runtimeMin: 12,
      maturity: 'PG-13',
      genres: ['Sci-Fi', 'Action'],
      cast: ['Derek de Lint', 'Sergio Hasselbaink'],
      palette: tosP,
      pack: StreamPack(
        primary:
            'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8',
        isHls: true,
        mirrors: [
          'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
        ],
      ),
    ),
    const Movie(
      id: 'bipbop',
      title: 'Bip-Bop advanced',
      tagline: 'Apple\u2019s reference stream, fMP4 packaged.',
      synopsis:
          'The advanced fMP4 reference stream from Apple — CMAF-packaged with '
          'multiple audio/video renditions and WebVTT subtitles. The exact '
          'packaging style used by modern streaming backends.',
      year: 2019,
      rating: 4.0,
      runtimeMin: 18,
      maturity: 'G',
      genres: ['Reference', 'Tech'],
      cast: ['Apple Developer'],
      palette: bipP,
      pack: StreamPack(
        primary:
            'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
        isHls: true,
        mirrors: [
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
        ],
      ),
    ),
    // ---- "For Bigger" — a 4-episode series → powers the next-episode
    //      preload pipeline and binge flow. Progressive MP4 renditions.
    //      (Runtime URL interpolation → non-const instances.) ----
    Movie(
      id: 'blazes',
      title: 'For Bigger Blazes',
      tagline: 'Chromecast. Episode 1.',
      synopsis:
          'Episode 1 of the "For Bigger" anthology — short, punchy, and '
          'progressive. A single-file delivery where CineFlux\u2019s ABR engine '
          'switches renditions by re-anchoring playback seamlessly.',
      year: 2016,
      rating: 3.9,
      runtimeMin: 2,
      maturity: 'G',
      genres: ['Short', 'Tech'],
      cast: ['Google'],
      palette: blazeP,
      pack: StreamPack(
        primary: '$gcs/ForBiggerBlazes.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/ForBiggerBlazes.mp4'},
      ),
      seriesName: 'For Bigger',
      season: 1,
      episode: 1,
      nextEpisodeId: 'escapes',
    ),
    Movie(
      id: 'escapes',
      title: 'For Bigger Escapes',
      tagline: 'Chromecast. Episode 2.',
      synopsis:
          'Episode 2 of the "For Bigger" anthology. While you watch, the '
          'preload manager is already warming the next episode\u2019s manifest and '
          'first bytes — so "next" feels instant.',
      year: 2016,
      rating: 3.9,
      runtimeMin: 2,
      maturity: 'G',
      genres: ['Short', 'Tech'],
      cast: ['Google'],
      palette: escapeP,
      pack: StreamPack(
        primary: '$gcs/ForBiggerEscapes.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/ForBiggerEscapes.mp4'},
      ),
      seriesName: 'For Bigger',
      season: 1,
      episode: 2,
      nextEpisodeId: 'fun',
    ),
    Movie(
      id: 'fun',
      title: 'For Bigger Fun',
      tagline: 'Chromecast. Episode 3.',
      synopsis:
          'Episode 3 of the "For Bigger" anthology — delivered straight from '
          'Google Cloud Storage\u2019s edge, cached aggressively after the first '
          'request (a tiny taste of what a CDN\u2019s 95%+ cache-hit ratio does).',
      year: 2016,
      rating: 4.0,
      runtimeMin: 2,
      maturity: 'G',
      genres: ['Short', 'Tech'],
      cast: ['Google'],
      palette: funP,
      pack: StreamPack(
        primary: '$gcs/ForBiggerFun.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/ForBiggerFun.mp4'},
      ),
      seriesName: 'For Bigger',
      season: 1,
      episode: 3,
      nextEpisodeId: 'joyrides',
    ),
    Movie(
      id: 'joyrides',
      title: 'For Bigger Joyrides',
      tagline: 'Chromecast. Episode 4.',
      synopsis:
          'Episode 4 — the season finale of the "For Bigger" anthology. '
          'Progressive delivery with full telemetry, retry and failover '
          'protections active.',
      year: 2016,
      rating: 4.0,
      runtimeMin: 2,
      maturity: 'G',
      genres: ['Short', 'Tech'],
      cast: ['Google'],
      palette: joyP,
      pack: StreamPack(
        primary: '$gcs/ForBiggerJoyrides.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/ForBiggerJoyrides.mp4'},
      ),
      seriesName: 'For Bigger',
      season: 1,
      episode: 4,
    ),
    Movie(
      id: 'dream',
      title: 'Elephants Dream',
      tagline: 'The first open movie. A machine\u2019s dream.',
      synopsis:
          'Two strange characters explore a capricious and seemingly endless '
          'machine. The world\u2019s first open movie, streamed progressively from '
          'Google\u2019s storage edge.',
      year: 2006,
      rating: 4.1,
      runtimeMin: 11,
      maturity: 'PG',
      genres: ['Animation', 'Surreal'],
      cast: ['Blender Foundation'],
      palette: dreamP,
      pack: StreamPack(
        primary: '$gcs/ElephantsDream.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/ElephantsDream.mp4'},
      ),
    ),
    Movie(
      id: 'bullrun',
      title: 'We Are Going On Bullrun',
      tagline: 'Rally culture, wide open.',
      synopsis:
          'A high-octane short about the Bullrun rally — progressive delivery, '
          'full telemetry, and CineFlux\u2019s resilience stack watching every byte.',
      year: 2016,
      rating: 3.6,
      runtimeMin: 3,
      maturity: 'G',
      genres: ['Documentary', 'Sport'],
      cast: ['Google'],
      palette: bullP,
      pack: StreamPack(
        primary: '$gcs/WeAreGoingOnBullrun.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/WeAreGoingOnBullrun.mp4'},
      ),
    ),
    Movie(
      id: 'grand',
      title: 'What Car Can You Get For A Grand?',
      tagline: 'Budget metal. Real answers.',
      synopsis:
          'A motoring classic short — proof that even modest content benefits '
          'from a serious delivery pipeline: adaptive quality, preloaded next '
          'chapters and a buffer that refuses to run dry.',
      year: 2016,
      rating: 3.7,
      runtimeMin: 3,
      maturity: 'G',
      genres: ['Documentary', 'Motoring'],
      cast: ['Google'],
      palette: grandP,
      pack: StreamPack(
        primary: '$gcs/WhatCarCanYouGetForAGrand.mp4',
        isHls: false,
        renditions: {'Auto': '$gcs/WhatCarCanYouGetForAGrand.mp4'},
      ),
    ),
  ];

  static Movie byId(String id) => all.firstWhere((m) => m.id == id,
      orElse: () => all.first);

  static List<Movie> series() => all.where((m) => m.isSeries).toList()
    ..sort((a, b) => a.episode!.compareTo(b.episode!));

  static List<Movie> search(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return [];
    return all.where((m) {
      final hay =
          '${m.title} ${m.tagline} ${m.genres.join(' ')} ${m.cast.join(' ')} ${m.seriesName ?? ''}'
              .toLowerCase();
      return hay.contains(t);
    }).toList();
  }

  static List<Movie> byGenre(String genre) =>
      all.where((m) => m.genres.any((g) => g.toLowerCase() == genre.toLowerCase())).toList();

  static List<String> genres() {
    final set = <String>{};
    for (final m in all) {
      set.addAll(m.genres);
    }
    return set.toList()..sort();
  }
}
