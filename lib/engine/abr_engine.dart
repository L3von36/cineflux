import 'buffer_monitor.dart';
import 'telemetry.dart';
import '../data/models.dart';

/// The Adaptive Bitrate engine — CineFlux's take on the hybrid
/// buffer+throughput decisioning used by Netflix/hls.js (BOLA, BBA).
///
/// ─── How the giants decide which quality to fetch next ──────────────────
/// 1. THROUGHPUT rule: pick the highest rendition that fits inside
///    bandwidth_estimate × safety_factor.
/// 2. BUFFER rule (BOLA/BBA): the fuller the buffer, the more ambitious we
///    may be; a draining buffer forces restraint.
/// 3. EMERGENCY: buffer < ~4s → switch to the rendition most likely to
///    survive, immediately, no hysteresis.
/// 4. HYSTERESIS: never flap. A change must be meaningful (>20% bitrate) or
///    persistent (two consecutive decisions) to happen. Up-switches are
///    rate-limited — networks recover gradually, not instantly.
/// ─────────────────────────────────────────────────────────────────────────
class ABRDecision {
  final QualityTier tier;
  final String reason;
  final bool emergency;
  const ABRDecision(this.tier, this.reason, {this.emergency = false});
}

class ABREngine {
  int _currentIndex = QualityTier.ladder.indexOf(QualityTier.ladder[3]); // start 720p
  int _lastSeenIndex = -1;
  DateTime _lastUpSwitch = DateTime.fromMillisecondsSinceEpoch(0);
  static const _upCooldown = Duration(seconds: 8);

  /// Manual quality lock (user picked a tier in the sheet). Null = auto.
  QualityTier? locked;

  /// Data Saver caps the ceiling regardless of bandwidth.
  bool dataSaver = false;

  int get currentIndex => _currentIndex;
  QualityTier get currentTier => QualityTier.ladder[_currentIndex];
  bool get isLocked => locked != null;

  /// The heart. Called every ~2s with fresh estimates.
  ABRDecision decide({
    required double bandwidthBps,
    required BufferMonitor buffer,
    required String? activeHost,
    TelemetrySink? sink,
  }) {
    // 0) Manual lock beats the engine.
    if (locked != null) {
      final idx = QualityTier.ladder.indexOf(locked!);
      if (idx != _currentIndex) {
        final d = ABRDecision(locked!, 'Manual lock: ${locked!.label}');
        _currentIndex = idx;
        return d;
      }
      return ABRDecision(currentTier, 'Manual lock held');
    }

    // 1) EMERGENCY — buffer about to run dry. This is the single biggest
    //    reason mainstream players "never" stall: they degrade gracefully
    //    BEFORE the frame freezes.
    if (buffer.starving && bandwidthBps > 0) {
      // Highest tier whose bitrate fits in bandwidth × 0.5 (pessimistic).
      final safe = QualityTier.nearestDown((bandwidthBps * 0.5).round());
      final idx = QualityTier.ladder.indexOf(safe);
      if (idx < _currentIndex) {
        _currentIndex = idx;
        return ABRDecision(safe, 'Buffer critical (${buffer.aheadSec.toStringAsFixed(1)}s) — emergency down-switch', emergency: true);
      }
      return ABRDecision(currentTier, 'Buffer critical, already at floor');
    }

    if (bandwidthBps <= 0) {
      return ABRDecision(currentTier, 'No bandwidth estimate yet — holding');
    }

    // 2) THROUGHPUT × BUFFER CONFIDENCE.
    //    confidence shrinks the usable bandwidth when the buffer is thin.
    double usable = bandwidthBps * buffer.confidence;

    // Data Saver: hard ceiling at 480p to protect the user's data plan.
    if (dataSaver) {
      final dsIdx = 2; // 480p
      if (_currentIndex > dsIdx) {
        _currentIndex = dsIdx;
        return ABRDecision(QualityTier.ladder[dsIdx], 'Data Saver ceiling (480p)');
      }
    }

    final target = QualityTier.nearestDown(usable.round());
    var idx = QualityTier.ladder.indexOf(target);
    if (dataSaver) idx = idx.clamp(0, 2).toInt();

    // 3) HYSTERESIS — anti-flapping.
    final candidate = QualityTier.ladder[idx];

    if (idx == _currentIndex) {
      _lastSeenIndex = idx;
      return ABRDecision(currentTier, 'Holding ${currentTier.label} — best fit for ${_mbps(usable)} usable');
    }

    if (idx > _currentIndex) {
      // Climbing: demand strong headroom (target bitrate ≤ 70% of usable)
      // AND a comfortable buffer AND cooldown elapsed.
      final headroomOk = candidate.bitrate <= usable * 0.7;
      final bufferOk = buffer.comfortable || buffer.smoothedSec >= BufferMonitor.targetSec;
      final cooledDown = DateTime.now().difference(_lastUpSwitch) > _upCooldown;
      final persistent = _lastSeenIndex == idx; // saw it twice
      if (headroomOk && bufferOk && cooledDown && persistent) {
        _lastUpSwitch = DateTime.now();
        _currentIndex = idx;
        return ABRDecision(candidate, 'Buffer comfortable (${buffer.smoothedSec.toStringAsFixed(0)}s) + ${_mbps(bandwidthBps)} bandwidth — up-switch');
      }
      _lastSeenIndex = idx;
      return ABRDecision(currentTier, 'Bandwidth allows ${candidate.label} but waiting for headroom/buffer/cooldown');
    }

    // 4) Down-switch: gentler rules. React quickly (that's the point),
    //    but skip meaningless micro-downgrades.
    final meaningful = candidate.bitrate <= currentTier.bitrate * 0.8;
    if (meaningful || buffer.trend < -2 || buffer.critical) {
      _currentIndex = idx;
      return ABRDecision(candidate, 'Bandwidth dipped to ${_mbps(bandwidthBps)} — down-switch to protect playback');
    }
    _lastSeenIndex = idx;
    return ABRDecision(currentTier, 'Bandwidth wobble ignored (hysteresis)');
  }

  String _mbps(double bps) => '${(bps / 1_000_000).toStringAsFixed(1)} Mbps';

  void reset() {
    _currentIndex = 3;
    _lastSeenIndex = -1;
    locked = null;
  }
}

/// Minimal callback hook so the engine stays UI-free.
typedef TelemetrySink = void Function(String message);
