import 'dart:async';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Bandwidth estimation — the EWMA (exponentially weighted moving average)
/// technique used by hls.js, ExoPlayer and Shaka Player.
///
/// How the giants do it:
///   • every downloaded segment is timed (bytes / elapsed);
///   • each sample is folded into an EWMA so the estimate reacts quickly to
///     drops (α on fresh samples) while staying smooth against spikes;
///   • the ABR layer then chooses a rendition *below* the estimate × safety
///     factor, which is why their streams rarely stall.
///
/// Because mpv consumes HLS segments internally, CineFlux measures with
/// lightweight ranged probes against the *same CDN hosts* the video comes
/// from — so estimates reflect the true route to the edge, and the probe
/// doubles as DNS/TLS/connection warm-up.
class BandwidthMeter {
  final http.Client _client = http.Client();
  final math.Random _rng = math.Random();

  double _bps = 0; // EWMA estimate, bits per second
  bool _primed = false;
  DateTime _lastProbe = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minProbeInterval = Duration(milliseconds: 1200);

  /// Current estimate in bits/second.
  double get estimateBps => _bps;

  /// Estimate in kbps for telemetry.
  double get estimateKbps => _bps / 1000;

  bool get primed => _primed;

  /// Number of samples folded into the estimate.
  int samples = 0;

  /// The EWMA smoothing factor. 0.25 ≈ hls.js default feel.
  final double alpha;

  BandwidthMeter({this.alpha = 0.25});

  /// Seed the estimate with a bigger probe (used once, before playback).
  /// Downloads up to [maxBytes] via a Range request from the video's own CDN.
  Future<double> seed({
    required String url,
    Map<String, String>? headers,
    int maxBytes = 256 * 1024,
  }) async {
    final bps = await probe(url, headers: headers, maxBytes: maxBytes);
    if (bps > 0 && !_primed) {
      _bps = bps;
      _primed = true;
      samples++;
    }
    return _bps;
  }

  /// Light periodic probe. Respects a minimum interval so probing never
  /// competes with playback for bandwidth.
  Future<double> lightProbe({
    required String url,
    Map<String, String>? headers,
    int maxBytes = 48 * 1024,
  }) async {
    final now = DateTime.now();
    if (now.difference(_lastProbe) < _minProbeInterval) return _bps;
    _lastProbe = now;
    final bps = await probe(url, headers: headers, maxBytes: maxBytes);
    if (bps <= 0) return _bps;
    if (!_primed) {
      _bps = bps;
      _primed = true;
    } else {
      _bps = alpha * bps + (1 - alpha) * _bps;
    }
    samples++;
    return _bps;
  }

  /// Measure instantaneous throughput by fetching up to [maxBytes] bytes.
  /// A Range header is used when supported; the streamed reader also caps
  /// natively. Returns bits/second, or 0 on failure.
  Future<double> probe(
    String url, {
    Map<String, String>? headers,
    int maxBytes = 64 * 1024,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final req = http.Request('GET', Uri.parse(url));
      req.headers['Range'] = 'bytes=0-${maxBytes - 1}';
      req.headers.addAll(headers ?? const {});
      final res =
          await _client.send(req).timeout(timeout, onTimeout: () => throw TimeoutException('probe'));
      if (res.statusCode >= 500) return 0;

      var received = 0;
      final byteStream = res.stream as Stream<List<int>>;
      await for (final chunk in byteStream) {
        received += chunk.length;
        if (received >= maxBytes) {
          await byteStream.cancel();
          break;
        }
      }
      sw.stop();
      if (received == 0 || sw.elapsedMilliseconds < 5) return 0;
      // bits per second
      return received * 8 * 1000 / sw.elapsedMilliseconds;
    } catch (_) {
      return 0;
    }
  }

  /// Deterministic-ish jittered start for staggered probes.
  Duration jitter(Duration base) =>
      Duration(milliseconds: (base.inMilliseconds * (0.5 + _rng.nextDouble())).round());

  void dispose() => _client.close();
}
