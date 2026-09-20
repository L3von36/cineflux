import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../engine/buffer_monitor.dart';
import '../../engine/stream_session.dart';
import '../../engine/telemetry.dart';

/// ── STREAM LAB v2 ───────────────────────────────────────────────────────
/// The signature CineFlux feature: a live engineering dashboard over your
/// own playback. Glow-rendered bandwidth graph with the emergency-buffer
/// threshold drawn in, stat cards, ABR switch feed, CDN probes, retry &
/// failover counters — the invisible machinery, visible.
class StreamLab extends StatelessWidget {
  final StreamSession session;
  final StreamTelemetry telemetry;
  final VoidCallback onClose;
  const StreamLab({
    super.key,
    required this.session,
    required this.telemetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: telemetry,
      builder: (context, _) {
        final pts = telemetry.points;
        final tier = session.abr.currentTier;
        final locked = session.abr.locked;

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppTheme.aurora,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [BoxShadow(color: AppTheme.indigo.withOpacity(.4), blurRadius: 14)],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 19, color: Colors.black),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STREAM LAB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13.5)),
                          Text('live delivery telemetry', style: TextStyle(fontSize: 10.5, color: AppTheme.textDim)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.green.withOpacity(.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: AppTheme.green),
                          SizedBox(width: 5),
                          Text('LIVE', style: TextStyle(fontSize: 8.5, letterSpacing: 1.6, fontWeight: FontWeight.w900, color: AppTheme.green)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.line),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  children: [
                    // ── Live stat cards ──
                    Row(
                      children: [
                        _StatCard(
                          label: 'BANDWIDTH (EWMA)',
                          value: Fmt.kbps(telemetry.currentKbps * 1000),
                          sub: '${telemetry.probes} probes folded in',
                          color: AppTheme.cyan,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'BUFFER AHEAD',
                          value: '${session.bufferMon.aheadSec.toStringAsFixed(1)}s',
                          sub: 'health ${Fmt.pct(session.bufferMon.health)}',
                          color: session.bufferMon.starving
                              ? AppTheme.red
                              : session.bufferMon.critical
                                  ? AppTheme.amber
                                  : AppTheme.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(
                          label: 'RENDITION',
                          value: locked != null ? locked.label : '${tier.label} · auto',
                          sub: tier.resolution,
                          color: AppTheme.violet,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'ACTIVE EDGE',
                          value: telemetry.activeHost ?? '—',
                          sub: '${telemetry.failovers} failovers · ${telemetry.retries} retries',
                          color: AppTheme.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Bandwidth graph ──
                    _SectionTitle('Throughput vs rendition', trailing: '${pts.length} samples'),
                    const SizedBox(height: 9),
                    Container(
                      height: 152,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: pts.length < 2
                          ? const Center(
                              child: Text('gathering samples…',
                                  style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _GraphPainter(points: pts),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        _LegendDot(color: AppTheme.cyan, label: 'bandwidth'),
                        SizedBox(width: 12),
                        _LegendDot(color: AppTheme.violet, label: 'rendition bitrate'),
                        SizedBox(width: 12),
                        _LegendDot(color: AppTheme.amber, label: 'buffer level'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Engine counters ──
                    _SectionTitle('Engine counters'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Counter('ABR switches', telemetry.switches),
                        _Counter('CDN failovers', telemetry.failovers),
                        _Counter('Retries', telemetry.retries),
                        _Counter('Preloads', telemetry.preloads),
                        _Counter('CDN probes', telemetry.probes),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Event log ──
                    _SectionTitle('Decision log'),
                    const SizedBox(height: 9),
                    for (final e in telemetry.events)
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: e.type == EngineEventType.cdnFailover || e.type == EngineEventType.error
                                ? AppTheme.red.withOpacity(.45)
                                : e.type == EngineEventType.abrSwitch
                                    ? AppTheme.violet.withOpacity(.35)
                                    : AppTheme.line,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: _eventColor(e.type).withOpacity(.13),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                e.typeLabel,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .8,
                                  color: _eventColor(e.type),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                e.message,
                                style: const TextStyle(fontSize: 11.5, height: 1.35, color: Color(0xFFD5DCE8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _eventColor(EngineEventType t) {
    return switch (t) {
      EngineEventType.abrSwitch => AppTheme.violet,
      EngineEventType.cdnProbe => AppTheme.cyan,
      EngineEventType.cdnFailover => AppTheme.red,
      EngineEventType.segmentRetry => AppTheme.amber,
      EngineEventType.preload => AppTheme.green,
      EngineEventType.bandwidthSample => AppTheme.cyan,
      EngineEventType.bufferWarning => AppTheme.amber,
      EngineEventType.error => AppTheme.red,
      EngineEventType.info => AppTheme.textMid,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionTitle(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 13,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: AppTheme.aurora,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
        const Spacer(),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(fontSize: 10.5, color: AppTheme.textDim)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: color.withOpacity(.8),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 8.5, letterSpacing: 1.3, color: AppTheme.textDim, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, shadows: [
                Shadow(color: color.withOpacity(.45), blurRadius: 10),
              ]),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: color.withOpacity(.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textDim)),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  const _Counter(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHi.withOpacity(.6),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: AppTheme.cyan),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
        ],
      ),
    );
  }
}

/// Triple-series graph v2: bandwidth (EWMA), rendition bitrate, buffer
/// level — glow strokes, soft fills, gridlines and the 4-second
/// emergency-buffer threshold line.
class _GraphPainter extends CustomPainter {
  final List<TelemetryPoint> points;
  _GraphPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final t0 = points.first.ts.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.ts.millisecondsSinceEpoch.toDouble();
    final tSpan = (t1 - t0).clamp(1.0, double.infinity).toDouble();

    final maxKbps = points.map((p) => p.kbps).reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity).toDouble();
    final maxMbps = points.map((p) => p.bitrateMbps).reduce((a, b) => a > b ? a : b).clamp(0.5, double.infinity).toDouble();

    Offset xy(DateTime ts, double v, double max) => Offset(
          ((ts.millisecondsSinceEpoch - t0) / tSpan) * size.width,
          size.height - (v / max) * (size.height - 10) - 5,
        );

    // Gridlines.
    final gridPaint = Paint()..color = Colors.white.withOpacity(.045);
    for (final frac in [0.25, 0.5, 0.75]) {
      canvas.drawLine(Offset(0, size.height * frac), Offset(size.width, size.height * frac), gridPaint);
    }

    // Emergency threshold — 4 seconds of buffer, the starvation line.
    final emergencyY = size.height - (BufferMonitor.emergencySec / BufferMonitor.maxSec) * (size.height - 10) - 5;
    final dashPaint = Paint()
      ..color = AppTheme.red.withOpacity(.4)
      ..strokeWidth = 1;
    const dash = 5.0;
    for (var x = 0.0; x < size.width; x += dash * 2) {
      canvas.drawLine(Offset(x, emergencyY), Offset(x + dash, emergencyY), dashPaint);
    }

    void series(double Function(TelemetryPoint) get, double max, Color color, [bool fill = true]) {
      final path = Path();
      var started = false;
      for (final p in points) {
        final o = xy(p.ts, get(p), max);
        if (started) {
          path.lineTo(o.dx, o.dy);
        } else {
          path.moveTo(o.dx, o.dy);
          started = true;
        }
      }
      if (fill) {
        final fillPath = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(colors: [
              color.withOpacity(.25),
              color.withOpacity(.02),
            ]).createShader(Offset.zero & size),
        );
      }
      // Glow pass, then the crisp stroke.
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    series((p) => p.bufferAheadSec, BufferMonitor.maxSec, AppTheme.amber, true);
    series((p) => p.bitrateMbps, maxMbps, AppTheme.violet, true);
    series((p) => p.kbps / 1000, maxKbps / 1000, AppTheme.cyan, true);

    // Live dot at the newest sample.
    final last = points.last;
    final lastO = xy(last.ts, last.kbps / 1000, maxKbps / 1000);
    canvas.drawCircle(lastO, 7, Paint()..color = AppTheme.cyan.withOpacity(.25));
    canvas.drawCircle(lastO, 3, Paint()..color = AppTheme.cyan);
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}
