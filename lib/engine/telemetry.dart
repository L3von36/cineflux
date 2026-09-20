import 'package:flutter/foundation.dart';

/// Live telemetry pipeline — the nervous system of the engine.
/// Every meaningful thing the delivery engine does becomes an event and a
/// datapoint, visualized live in the Stream Lab overlay.

enum EngineEventType {
  info,
  bandwidthSample,
  abrSwitch,
  bufferWarning,
  cdnProbe,
  cdnFailover,
  segmentRetry,
  preload,
  error,
}

class EngineEvent {
  final DateTime ts;
  final EngineEventType type;
  final String message;
  final String? detail;
  const EngineEvent(this.type, this.message, {this.detail, DateTime? ts})
      : ts = ts ?? DateTime.now();

  String get typeLabel => switch (type) {
        EngineEventType.abrSwitch => 'ABR',
        EngineEventType.cdnProbe => 'CDN',
        EngineEventType.cdnFailover => 'FAILOVER',
        EngineEventType.segmentRetry => 'RETRY',
        EngineEventType.preload => 'PRELOAD',
        EngineEventType.bandwidthSample => 'NET',
        EngineEventType.bufferWarning => 'BUFFER',
        EngineEventType.error => 'ERROR',
        EngineEventType.info => 'INFO',
      };
}

class TelemetryPoint {
  final DateTime ts;
  final double kbps; // estimated throughput (kilobits/s)
  final double bufferAheadSec;
  final double bitrateMbps; // active rendition bitrate
  const TelemetryPoint({
    required this.ts,
    required this.kbps,
    required this.bufferAheadSec,
    required this.bitrateMbps,
  });
}

/// ChangeNotifier consumed by Stream Lab.
class StreamTelemetry extends ChangeNotifier {
  static const int maxPoints = 240;
  static const int maxEvents = 120;

  final List<TelemetryPoint> _points = [];
  final List<EngineEvent> _events = [];

  // Counters — the story of "why it didn't break".
  int switches = 0;
  int retries = 0;
  int failovers = 0;
  int preloads = 0;
  int probes = 0;

  double _currentKbps = 0;
  double get currentKbps => _currentKbps;
  double get currentMbps => _currentKbps / 1000;

  String? _activeHost;
  String? get activeHost => _activeHost;
  void setHost(String h) {
    if (_activeHost == h) return;
    _activeHost = h;
    notifyListeners();
  }

  List<TelemetryPoint> get points => List.unmodifiable(_points);
  List<EngineEvent> get events => List.unmodifiable(_events.reversed.take(40));

  void sample({
    required double kbps,
    required double bufferAheadSec,
    required double bitrateMbps,
  }) {
    _currentKbps = kbps;
    _points.add(TelemetryPoint(
      ts: DateTime.now(),
      kbps: kbps,
      bufferAheadSec: bufferAheadSec,
      bitrateMbps: bitrateMbps,
    ));
    if (_points.length > maxPoints) _points.removeRange(0, _points.length - maxPoints);
    notifyListeners();
  }

  void log(EngineEvent e) {
    _events.add(e);
    if (_events.length > maxEvents) _events.removeRange(0, _events.length - maxEvents);
    switch (e.type) {
      case EngineEventType.abrSwitch:
        switches++;
      case EngineEventType.segmentRetry:
        retries++;
      case EngineEventType.cdnFailover:
        failovers++;
      case EngineEventType.preload:
        preloads++;
      case EngineEventType.cdnProbe || EngineEventType.bandwidthSample:
        probes++;
      default:
        break;
    }
    notifyListeners();
  }

  void reset({bool keepHost = true}) {
    _points.clear();
    _events.clear();
    switches = retries = failovers = preloads = probes = 0;
    _currentKbps = 0;
    if (!keepHost) _activeHost = null;
    notifyListeners();
  }
}
