import 'dart:async';
import 'dart:math' as math;

/// Retry with exponential backoff + full jitter — the pattern behind
/// "streams don't break". Individual segment/metadata requests fail all the
/// time (blips, 502s, edge hiccups). The trick is to retry intelligently:
/// fast first, then progressively calmer, with randomization so thousands of
/// clients don't stampede the origin at the same moment (the "thundering
/// herd" that Origin Shield exists to absorb).
class RetryPolicy {
  final math.Random _rng = math.Random();

  final int maxAttempts;
  final Duration baseDelay;

  RetryPolicy({this.maxAttempts = 3, this.baseDelay = const Duration(milliseconds: 350)});

  Future<T> run<T>(
    Future<T> Function() task, {
    String? label,
    void Function(int attempt, Object error, Duration wait)? onRetry,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await task();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        final exp = baseDelay * math.pow(2, attempt - 1).toDouble();
        // Full jitter: wait a random fraction of the exponential backoff.
        final wait = Duration(milliseconds: (exp.inMilliseconds * (0.5 + _rng.nextDouble() * 0.5)).round());
        onRetry?.call(attempt, e, wait);
        await Future<void>.delayed(wait);
      }
    }
  }

  /// Same policy, but never throws — returns null after exhausting attempts.
  Future<T?> runOrNull<T>(Future<T> Function() task, {String? label}) async {
    try {
      return await run(task, label: label);
    } catch (_) {
      return null;
    }
  }
}
