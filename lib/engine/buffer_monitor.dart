import 'dart:collection';

/// Buffer health monitoring — the other half of every ABR decision.
///
/// Netflix/hls.js style: the player tracks how many seconds of video sit
/// ready in the buffer *ahead of the playhead*. Full buffer → permission to
/// climb the quality ladder. Shrinking buffer → step down *before* the
/// playback stalls. An emergency threshold triggers an immediate down-switch.
class BufferMonitor {
  /// Seconds of media buffered ahead of the playhead.
  double aheadSec = 0;

  /// EMA-smoothed buffer level (less noisy than instant values).
  double smoothedSec = 0;

  /// How the buffer has been trending over the last samples
  /// (positive = filling up, negative = draining).
  double trend = 0;

  final Queue<double> _history = Queue<double>();
  static const int historyLen = 12;

  // Thresholds — tuned like mainstream players.
  static const double emergencySec = 4; // below: starve imminent → drop NOW
  static const double criticalSec = 8; // below: danger, no up-switches
  static const double targetSec = 40; // ideal fill level
  static const double maxSec = 90; // beyond: plenty; safe to climb

  /// Latest 12 buffer samples, for the Stream Lab sparkline.
  List<double> get history => _history.toList();

  void update({required Duration position, required Duration buffered}) {
    aheadSec = (buffered - position).inMilliseconds / 1000;
    if (aheadSec < 0) aheadSec = 0;

    if (smoothedSec == 0) {
      smoothedSec = aheadSec;
    } else {
      smoothedSec = 0.4 * aheadSec + 0.6 * smoothedSec;
    }

    _history.addLast(aheadSec);
    if (_history.length > historyLen) _history.removeFirst();

    // Linear trend over the recent window.
    if (_history.length >= 3) {
      final list = _history.toList();
      final first = list.first, last = list.last;
      trend = last - first;
    }
  }

  /// 0 = starving, 1 = luxuriously full.
  double get health => (smoothedSec / targetSec).clamp(0.0, 1.0);

  bool get starving => aheadSec <= emergencySec;
  bool get critical => smoothedSec < criticalSec;
  bool get comfortable => smoothedSec >= maxSec || (smoothedSec >= targetSec && trend >= 0);

  /// Multiplier on the bandwidth estimate before trusting it for rendition
  /// selection. A draining buffer means the network lied to us recently —
  /// be pessimistic. A full buffer means we have room to be ambitious.
  double get confidence {
    if (starving) return 0.45;
    if (critical) return 0.60;
    if (smoothedSec < targetSec) return 0.72;
    return 0.88;
  }
}
