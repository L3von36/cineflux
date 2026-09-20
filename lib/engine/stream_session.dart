import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/format.dart';
import '../data/catalog.dart';
import '../data/library_repo.dart';
import '../data/models.dart';
import 'abr_engine.dart';
import 'bandwidth_meter.dart';
import 'buffer_monitor.dart';
import 'cdn_selector.dart';
import 'preload_manager.dart';
import 'retry_policy.dart';
import 'telemetry.dart';

/// The session conductor — binds the player to every engine module and turns
/// raw playback into a managed, self-healing, adaptive stream.
///
/// Lifecycle of a session:
///   1. CDN probe      — measure every mirror, pick the fastest edge.
///   2. Bandwidth seed — big probe against the chosen edge → starting tier.
///   3. Manifest warm  — preload manager opens TLS + fetches the playlist.
///   4. Playback       — telemetry samples every 1s, ABR decides every 2s.
///   5. Self-healing   — on stream errors: retry → CDN failover → recover
///                       at the exact position (never restart from zero).
///   6. Next-up        — near the end, prefetch the next episode manifest.
class StreamSession extends ChangeNotifier {
  final Player player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: 64 * 1024 * 1024, // 64MB — generous buffer like desktop players
      logLevel: MPVLogLevel.warn,
    ),
  );
  late final VideoController controller = VideoController(player);

  final StreamTelemetry telemetry = StreamTelemetry();
  final BandwidthMeter meter = BandwidthMeter();
  final BufferMonitor bufferMon = BufferMonitor();
  final ABREngine abr = ABREngine();
  final CdnSelector cdn = CdnSelector();
  final PreloadManager preload = PreloadManager();
  final RetryPolicy retry = RetryPolicy(maxAttempts: 3);
  final LibraryRepo lib = LibraryRepo.I;

  Movie? movie;
  bool starting = false;
  bool recovered = false;
  String? lastFailure;

  // Live playback state mirrored from player streams.
  Duration _pos = Duration.zero;
  Duration _buf = Duration.zero;
  Duration _dur = Duration.zero;
  Duration get position => _pos;
  Duration get buffered => _buf;
  Duration get duration => _dur;
  bool get buffering => player.state.buffering;

  String _activeUrl = '';
  String get activeUrl => _activeUrl;
  QualityTier? _appliedTier;
  bool _hlsCapSupported = true;

  bool _nextPreloaded = false;
  bool dataSaver = false;
  bool autoplayNext = true;

  /// UI hook: fired when an episode finishes and another follows.
  void Function(Movie next)? onEpisodeEnded;

  Timer? _sampleTimer;
  Timer? _abrTimer;
  final List<StreamSubscription> _subs = [];

  // ---------------------------------------------------------------- start

  Future<void> start(Movie m, {Duration? resumeAt}) async {
    await stop(keepTelemetry: false);
    starting = true;
    movie = m;
    recovered = false;
    lastFailure = null;
    telemetry.reset(keepHost: false);
    preload.telemetry = telemetry;
    abr.reset();
    abr.dataSaver = dataSaver = await lib.dataSaver();
    autoplayNext = await lib.autoplayNext();
    notifyListeners();

    telemetry.log(EngineEvent(EngineEventType.info, 'Session start — "${m.title}" (${m.pack.isHls ? 'HLS ladder' : 'progressive'})'));

    // 1 ── Multi-CDN probe.
    cdn.load(m.pack.urls);
    final best = await cdn.probeAll(onResult: (e, ms) {
      telemetry.log(EngineEvent(
        EngineEventType.cdnProbe,
        ms >= 0
            ? 'CDN ${e.host} alive — ${ms.toStringAsFixed(0)}ms'
            : 'CDN ${e.host} unreachable — deprioritised',
        detail: e.url,
      ));
    });
    _activeUrl = best?.url ?? m.pack.primary;
    telemetry.setHost(Uri.parse(_activeUrl).host);

    // 2 ── Seed the bandwidth estimate (EWMA needs a first sample).
    final seedBps = await meter.seed(url: _activeUrl, maxBytes: 256 * 1024);
    if (seedBps > 0) {
      telemetry.log(EngineEvent(EngineEventType.bandwidthSample,
          'Bandwidth estimate seeded at ${Fmt.kbps(seedBps)}'));
      final startTier = QualityTier.nearestDown((seedBps * 0.8).round());
      abr.locked = null;
      _appliedTier = startTier;
      await _enforceHlsCap(startTier);
      telemetry.log(EngineEvent(EngineEventType.abrSwitch,
          'Starting at ${startTier.label} (${startTier.resolution}) — headroom under ${Fmt.kbps(seedBps)}'));
    } else {
      telemetry.log(const EngineEvent(EngineEventType.bandwidthSample,
          'Bandwidth probe failed — native ABR will carry us'));
    }

    // 3 ── Warm the manifest (TLS + CDN cache) before opening the player.
    await preload.warmup(_activeUrl);

    // 4 ── Open with retry; recover at the resume position on failure.
    await _openWithRetry(_activeUrl, resumeAt ?? Duration.zero);

    starting = false;
    _startLoops();
    notifyListeners();
  }

  Future<void> _openWithRetry(String url, Duration at) async {
    try {
      await retry.run(
        () async {
          await player.open(Media(url), play: false);
          return true;
        },
        label: 'open',
        onRetry: (attempt, err, wait) {
          telemetry.log(EngineEvent(EngineEventType.segmentRetry,
              'Open attempt $attempt failed — retrying in ${wait.inMilliseconds}ms (exponential backoff + jitter)'));
        },
      );
      if (at > Duration.zero) {
        await player.seek(at);
      }
      await player.play();
      telemetry.setHost(Uri.parse(url).host);
      _activeUrl = url;
    } catch (e) {
      lastFailure = 'Could not open stream: $e';
      telemetry.log(EngineEvent(EngineEventType.error, 'Playback open failed after 3 attempts — all mirrors exhausted'));
    }
  }

  // ---------------------------------------------------------------- loops

  void _startLoops() {
    _stopLoops();

    _subs.add(player.stream.position.listen((p) => _pos = p));
    _subs.add(player.stream.buffer.listen((b) => _buf = b));
    _subs.add(player.stream.duration.listen((d) => _dur = d));
    _subs.add(player.stream.error.listen(_onStreamError));
    _subs.add(player.stream.completed.listen(_onCompleted));

    // Telemetry heartbeat — 1s.
    _sampleTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      bufferMon.update(position: _pos, buffered: _buf);
      if (_activeUrl.isNotEmpty) {
        await meter.lightProbe(url: _activeUrl, maxBytes: 48 * 1024);
      }
      telemetry.sample(
        kbps: meter.estimateKbps,
        bufferAheadSec: bufferMon.aheadSec,
        bitrateMbps: (_appliedTier?.bitrate ?? player.state.bitrate ?? 0) / 1_000_000,
      );

      // Persist progress (resume support).
      if (_dur > Duration.zero) {
        final frac = _pos.inMilliseconds / _dur.inMilliseconds;
        await lib.saveProgress(movie!.id, frac);
      }

      // Next-episode prefetch at 85% — the YouTube trick.
      if (!_nextPreloaded && movie?.nextEpisodeId != null && _dur > Duration.zero) {
        final frac = _pos.inMilliseconds / _dur.inMilliseconds;
        if (frac >= 0.85) {
          _nextPreloaded = true;
          final next = Catalog.byId(movie!.nextEpisodeId!);
          unawaited(preload.prefetchNext(next));
        }
      }
    });

    // ABR heartbeat — 2s.
    _abrTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (movie == null || meter.estimateBps <= 0) return;
      final decision = abr.decide(
        bandwidthBps: meter.estimateBps,
        buffer: bufferMon,
        activeHost: telemetry.activeHost,
      );
      if (decision.tier.bitrate != (_appliedTier?.bitrate ?? -1)) {
        _appliedTier = decision.tier;
        unawaited(_enforceHlsCap(decision.tier));
        telemetry.log(EngineEvent(
          decision.emergency ? EngineEventType.bufferWarning : EngineEventType.abrSwitch,
          'ABR → ${decision.tier.label} — ${decision.reason}',
        ));
      }
    });
  }

  void _stopLoops() {
    _sampleTimer?.cancel();
    _abrTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  // ------------------------------------------------------------ resilience

  void _onStreamError(String err) {
    telemetry.log(EngineEvent(EngineEventType.error, 'Player error: $err'));
    unawaited(_selfHeal());
  }

  /// The "streams don't break" routine:
  ///   report failure → choose another CDN → reopen at the CURRENT position.
  Future<void> _selfHeal() async {
    if (movie == null) return;
    final resume = _pos;
    telemetry.log(EngineEvent(EngineEventType.segmentRetry,
        'Self-healing engaged at ${Fmt.clock(resume)} — reporting failure to steering layer'));
    cdn.reportFailure(_activeUrl);
    final next = cdn.failoverFrom(_activeUrl);
    if (next != null && next.url != _activeUrl) {
      telemetry.log(EngineEvent(EngineEventType.cdnFailover,
          'Failing over ${Uri.parse(_activeUrl).host} → ${next.host} — recovering at ${Fmt.clock(resume)}'));
      _activeUrl = next.url;
      await _openWithRetry(next.url, resume);
      recovered = true;
      notifyListeners();
    } else {
      telemetry.log(const EngineEvent(EngineEventType.info,
          'No healthier mirror right now — player buffer + native retry are absorbing the outage'));
    }
  }

  // ------------------------------------------------------------ controls

  Future<void> playOrPause() => player.playOrPause();
  Future<void> seek(Duration d) => player.seek(d);
  Future<void> setRate(double r) => player.setRate(r);
  Future<void> setVolume(double v) => player.setVolume(v);

  void setLockedTier(QualityTier? tier) {
    abr.locked = tier;
    if (tier != null) {
      _appliedTier = tier;
      unawaited(_enforceHlsCap(tier));
      telemetry.log(EngineEvent(EngineEventType.abrSwitch, 'Quality locked to ${tier.label} (${tier.resolution})'));
    } else {
      unawaited(_enforceHlsCap(null));
      telemetry.log(const EngineEvent(EngineEventType.abrSwitch, 'Back to Auto — ABR engine resumed'));
    }
    notifyListeners();
  }

  Future<void> setDataSaver(bool on) async {
    dataSaver = on;
    abr.dataSaver = on;
    await lib.setDataSaver(on);
    notifyListeners();
  }

  Future<void> setAutoplayNext(bool on) async {
    autoplayNext = on;
    await lib.setAutoplayNext(on);
    notifyListeners();
  }

  /// HLS: cap the ladder via mpv's hls-bitrate (max rendition bitrate).
  /// Progressive: switch rendition files while preserving the playhead.
  Future<void> _enforceHlsCap(QualityTier? tier) async {
    if (movie == null) return;
    if (movie!.pack.isHls) {
      if (!_hlsCapSupported) return;
      try {
        final platform = player.platform;
        if (platform is NativePlayer) {
          await platform.setProperty('hls-bitrate', tier == null ? 'no' : '${tier.bitrate}');
        }
      } catch (_) {
        _hlsCapSupported = false;
        telemetry.log(const EngineEvent(EngineEventType.info,
            'Rendition capping unavailable on this build — mpv native ABR active'));
      }
    } else {
      final rends = movie!.pack.renditions;
      if (rends != null && rends.length > 1) {
        final url = rends[tier?.label] ?? rends['Auto'];
        if (url != null && url != _activeUrl) {
          final at = _pos;
          telemetry.log(EngineEvent(EngineEventType.abrSwitch,
              'Rendition switch → ${tier?.label ?? "Auto"} — re-anchoring playhead at ${Fmt.clock(at)}'));
          await _openWithRetry(url, at);
        }
      }
    }
  }

  void _onCompleted(bool completed) {
    if (!completed) return;
    unawaited(lib.saveProgress(movie!.id, 1.0));
    if (movie?.nextEpisodeId != null && autoplayNext) {
      final next = Catalog.byId(movie!.nextEpisodeId!);
      telemetry.log(EngineEvent(EngineEventType.preload,
          '"${next.title}" preloaded earlier — launching next episode'));
      onEpisodeEnded?.call(next);
    }
  }

  // ---------------------------------------------------------------- stop

  Future<void> stop({bool keepTelemetry = true}) async {
    _stopLoops();
    if (movie != null && _dur > Duration.zero) {
      final frac = _pos.inMilliseconds / _dur.inMilliseconds;
      await lib.saveProgress(movie!.id, frac);
    }
    try {
      await player.pause();
    } catch (_) {}
    starting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLoops();
    meter.dispose();
    cdn.dispose();
    preload.dispose();
    player.dispose();
    super.dispose();
  }
}
