import 'dart:ui';

/// A generated color palette used to paint poster art, ambient glow and
/// accents for a title — all local, zero image fetches needed.
class Palette {
  final Color a, b, c;
  const Palette(this.a, this.b, this.c);
}

/// One rung of the encoding ladder (Netflix calls this the "bitrate ladder").
/// Every title is delivered as multiple renditions; the ABR engine hops
/// between them based on bandwidth + buffer health.
class QualityTier {
  final String label;
  final String resolution;
  final int bitrate; // bits per second
  const QualityTier(this.label, this.resolution, this.bitrate);

  static const ladder = [
    QualityTier('240p', '426×240', 400_000),
    QualityTier('360p', '640×360', 800_000),
    QualityTier('480p', '854×480', 1_400_000),
    QualityTier('720p', '1280×720', 3_000_000),
    QualityTier('1080p', '1920×1080', 6_000_000),
    QualityTier('1440p', '2560×1440', 12_000_000),
    QualityTier('4K', '3840×2160', 18_000_000),
  ];

  static QualityTier nearestDown(int bandwidthBps) {
    for (final t in ladder.reversed) {
      if (t.bitrate <= bandwidthBps) return t;
    }
    return ladder.first;
  }
}

/// How a title is actually delivered over the network.
class StreamPack {
  /// Primary playback URL (HLS master playlist or progressive MP4).
  final String primary;

  /// True when [primary] is an HLS master playlist (multi-variant).
  final bool isHls;

  /// Mirror URLs on *different CDN hosts* — powers real multi-CDN failover.
  final List<String> mirrors;

  /// Optional explicit progressive renditions (label → url). When present,
  /// the ABR engine performs true rendition switching by seeking seamlessly.
  final Map<String, String>? renditions;

  const StreamPack({
    required this.primary,
    this.isHls = true,
    this.mirrors = const [],
    this.renditions,
  });

  /// All hosts involved in delivery, primary first — used by the CDN selector.
  List<String> get urls => [primary, ...mirrors];
}

class Movie {
  final String id;
  final String title;
  final String tagline;
  final String synopsis;
  final int year;
  final double rating;
  final int runtimeMin;
  final String maturity;
  final List<String> genres;
  final List<String> cast;
  final Palette palette;
  final StreamPack pack;

  /// Series metadata (for the next-episode preload pipeline).
  final String? seriesName;
  final int? season;
  final int? episode;
  final String? nextEpisodeId;

  const Movie({
    required this.id,
    required this.title,
    required this.tagline,
    required this.synopsis,
    required this.year,
    required this.rating,
    required this.runtimeMin,
    required this.maturity,
    required this.genres,
    required this.cast,
    required this.palette,
    required this.pack,
    this.seriesName,
    this.season,
    this.episode,
    this.nextEpisodeId,
  });

  bool get isSeries => seriesName != null;

  String get seriesLabel =>
      isSeries ? 'S${season}:E${episode} · $seriesName' : '$runtimeMin min';

  /// A short, rich description used by detail/search surfaces.
  String get displaySubtitle =>
      isSeries ? '$seriesName · Season $season, Episode $episode' : '$year · ${genres.first}';
}
