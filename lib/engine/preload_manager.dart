import 'dart:async';

import 'package:http/http.dart' as http;

import '../data/models.dart';
import 'retry_policy.dart';
import 'telemetry.dart';

/// Preload pipeline — why "next" always feels instant.
///
/// ─── What YouTube/Netflix do before you press play ──────────────────────
/// • Manifest warm-up: fetch the playlist + open TLS connections to the CDN
///   edge BEFORE playback starts, so the first segment arrives immediately.
/// • Next-episode prefetch: when you approach the end of an episode (or
///   even while you're browsing), the next item's manifest and first bytes
///   are already travelling toward your device.
/// • On YouTube this is why the up-next video often starts in <100ms.
/// ─────────────────────────────────────────────────────────────────────────
class PreloadManager {
  final http.Client _client = http.Client();
  final RetryPolicy retry = RetryPolicy(maxAttempts: 2);
  final Map<String, DateTime> _warmed = {};
  StreamTelemetry? telemetry;

  /// Warm the manifest for a URL: DNS + TLS + CDN cache in one small fetch.
  /// Returns latency in ms (or -1).
  Future<double> warmup(String url, {Map<String, String>? headers, bool quiet = false}) async {
    if (_warmed.containsKey(url)) return -1;
    _warmed[url] = DateTime.now();
    final sw = Stopwatch()..start();
    try {
      await retry.run(() async {
        final res = await _client
            .get(Uri.parse(url), headers: {'Range': 'bytes=0-32767', ...?headers})
            .timeout(const Duration(seconds: 6));
        if (res.statusCode >= 500) throw Exception('warmup ${res.statusCode}');
        return res;
      });
      sw.stop();
      if (!quiet) {
        telemetry?.log(EngineEvent(EngineEventType.preload,
            'Manifest warmed via ${Uri.parse(url).host} in ${sw.elapsedMilliseconds}ms — first segment will fly',
            detail: url));
      }
      return sw.elapsedMilliseconds.toDouble();
    } catch (_) {
      _warmed.remove(url);
      if (!quiet) {
        telemetry?.log(EngineEvent(EngineEventType.info, 'Manifest warm-up skipped (edge unreachable)'));
      }
      return -1;
    }
  }

  /// Called during playback: prefetch the NEXT episode when the current one
  /// passes [threshold] of completion (default 85% — YouTube prefetches
  /// around this point too).
  Future<void> prefetchNext(Movie? next) async {
    if (next == null) return;
    await warmup(next.pack.primary, quiet: false);
    // Warm a mirror too — insurance for the future session.
    if (next.pack.mirrors.isNotEmpty) {
      await warmup(next.pack.mirrors.first, quiet: true);
    }
  }

  bool wasWarmed(String url) => _warmed.containsKey(url);

  void dispose() => _client.close();
}
