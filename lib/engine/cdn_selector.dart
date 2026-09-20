import 'package:http/http.dart' as http;

import 'retry_policy.dart';
import 'telemetry.dart';

/// Multi-CDN selector — a miniature version of the multi-CDN steering the
/// big services run.
///
/// ─── How the giants keep streams alive at scale ─────────────────────────
/// • Content sits on SEVERAL independent CDNs (Akamai, Fastly, CloudFront,
///   their own Open Connect boxes inside ISPs...).
/// • A steering layer continuously probes each provider's health/latency
///   and routes each viewer to the best edge.
/// • When one CDN degrades, traffic shifts to the others mid-playback —
///   the viewer sees, at most, a tiny spinner. Streams "don't break"
///   because failures are absorbed invisibly.
/// ─────────────────────────────────────────────────────────────────────────
class CdnEndpoint {
  final String url; // full playback URL served by this endpoint
  final String host;
  double latencyMs = -1; // -1 = unknown
  int consecutiveFailures = 0;
  DateTime? lastProbedAt;

  CdnEndpoint(this.url)
      : host = Uri.tryParse(url)?.host ?? url;

  bool get alive => consecutiveFailures < 3;
}

class CdnSelector {
  final http.Client _client = http.Client();
  final RetryPolicy retry = RetryPolicy(maxAttempts: 2);

  final Map<String, CdnEndpoint> _endpoints = {};
  CdnEndpoint? _active;

  CdnEndpoint? get active => _active;
  List<CdnEndpoint> get endpoints => _endpoints.values.toList();

  /// Register the full mirror set for a title (primary first).
  void load(List<String> urls) {
    _endpoints.clear();
    _active = null;
    for (final u in urls) {
      _endpoints[u] = CdnEndpoint(u);
    }
  }

  /// Probe every endpoint (HEAD is enough to measure reachability + latency;
  /// ANY HTTP status — even 403/405 — proves the route works).
  Future<CdnEndpoint?> probeAll({
    void Function(CdnEndpoint e, double ms)? onResult,
    Map<String, String>? headers,
  }) async {
    final results = await Future.wait(_endpoints.values.map((e) => _probe(e, headers: headers)));
    if (onResult != null) {
      for (final e in results) {
        onResult.call(e, e.latencyMs);
      }
    }
    final alive = results.where((e) => e.alive && e.latencyMs >= 0).toList()
      ..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    _active = alive.isNotEmpty ? alive.first : (results.isNotEmpty ? results.first : null);
    return _active;
  }

  Future<CdnEndpoint> _probe(CdnEndpoint e, {Map<String, String>? headers}) async {
    final sw = Stopwatch()..start();
    try {
      await retry.runOrNull(() async {
        sw.reset();
        final res = await _client
            .head(Uri.parse(e.url), headers: headers ?? const {})
            .timeout(const Duration(seconds: 5));
        // Any HTTP response = the route is alive.
        if (res.statusCode >= 500) throw Exception('probe ${res.statusCode}');
        return res;
      });
      e.latencyMs = sw.elapsedMilliseconds.toDouble();
      e.consecutiveFailures = 0;
    } catch (_) {
      e.latencyMs = -1;
      e.consecutiveFailures++;
    }
    e.lastProbedAt = DateTime.now();
    return e;
  }

  /// Mid-stream failover: pick the next-best ALIVE endpoint, excluding the
  /// one that just failed. Returns null if every mirror is exhausted.
  CdnEndpoint? failoverFrom(String failedUrl) {
    final failed = _endpoints[failedUrl];
    failed?.consecutiveFailures++;
    final candidates = _endpoints.values
        .where((e) => e.url != failedUrl && e.alive)
        .toList()
      ..sort((a, b) {
        final aScore = (a.latencyMs < 0 ? 9999 : a.latencyMs) + a.consecutiveFailures * 500;
        final bScore = (b.latencyMs < 0 ? 9999 : b.latencyMs) + b.consecutiveFailures * 500;
        return aScore.compareTo(bScore);
      });
    _active = candidates.isNotEmpty ? candidates.first : null;
    return _active;
  }

  void reportFailure(String url) {
    _endpoints[url]?.consecutiveFailures++;
  }

  void dispose() => _client.close();
}
