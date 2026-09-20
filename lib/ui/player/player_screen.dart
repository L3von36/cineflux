import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../engine/stream_session.dart';
import 'quality_sheet.dart';
import 'stream_lab.dart';

/// The player: mpv-grade playback (media_kit) under a fully custom
/// CineFlux control layer — buffered-progress seek bar, ±10s double-tap
/// seek, speed control, quality ladder, and the Stream Lab telemetry
/// overlay that shows the delivery engine working in real time.
class PlayerScreen extends StatefulWidget {
  final Movie movie;
  final AppState app;
  const PlayerScreen({super.key, required this.movie, required this.app});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late Movie _movie;
  bool _controlsVisible = true;
  bool _labOpen = false;
  DateTime _lastTouch = DateTime.now();
  int _doubleTapSide = 0; // -1 left, 1 right

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = widget.app.session;
    session.onEpisodeEnded = _onNextEpisode;
    // Resume where the user left off.
    final frac = await widget.app.repo.progressOf(_movie.id);
    final dur = Duration(minutes: _movie.runtimeMin);
    final resumeAt = frac > 0.01 ? Duration(milliseconds: (dur.inMilliseconds * frac).round()) : null;
    await session.start(_movie, resumeAt: resumeAt);
    if (mounted) setState(() {});
  }

  void _onNextEpisode(Movie next) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PlayerScreen(movie: next, app: widget.app),
    ));
  }

  void _bumpControls() {
    _lastTouch = DateTime.now();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
  }

  @override
  void dispose() {
    widget.app.session.onEpisodeEnded = null;
    widget.app.session.stop();
    widget.app.refresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.app.session;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([session, session.telemetry]),
        builder: (context, _) {
          final started = session.movie?.id == _movie.id && !session.starting;
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Video surface ──
              if (started)
                Video(
                  controller: session.controller,
                  controls: NoVideoControls,
                )
              else
                _LoadingPane(session: session, movie: _movie),

              // ── Gesture layer ──
              if (started) _buildGestures(),

              // ── Controls overlay ──
              if (started && _controlsVisible) _buildControls(context, session),

              // ── Stream Lab ──
              if (started && _labOpen) _buildLab(context, session),

              // ── Double-tap seek ripple ──
              if (_doubleTapSide != 0) _SeekRipple(side: _doubleTapSide),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------- gestures

  Widget _buildGestures() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _bumpControls,
            onDoubleTap: () => _doubleTapSeek(-1),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _bumpControls,
            onDoubleTap: () => _doubleTapSeek(1),
          ),
        ),
      ],
    );
  }

  Future<void> _doubleTapSeek(int dir) async {
    final session = widget.app.session;
    _doubleTapSide = dir;
    setState(() {});
    await session.seek(session.position + Duration(seconds: dir * 10));
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) setState(() => _doubleTapSide = 0);
  }

  // ------------------------------------------------------------- controls

  Widget _buildControls(BuildContext context, StreamSession session) {
    // auto-hide timer
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      if (DateTime.now().difference(_lastTouch).inMilliseconds >= 3400 &&
          session.player.state.playing &&
          !_labOpen) {
        setState(() => _controlsVisible = false);
      }
    });

    final pos = session.position;
    final dur = session.duration <= Duration.zero ? const Duration(minutes: 1) : session.duration;
    final bufferedAhead = session.buffered > pos ? session.buffered : pos;
    final playing = session.player.state.playing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _bumpControls,
      child: Container(
        color: Colors.black.withOpacity(.28),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          '${_movie.isSeries ? _movie.seriesLabel : _movie.year} · ${Uri.parse(session.activeUrl).host}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _TopPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Stream Lab',
                    onTap: () => setState(() => _labOpen = true),
                  ),
                  const SizedBox(width: 10),
                ],
              ),

              const Spacer(),

              // ── Center cluster ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundBtn(icon: Icons.replay_10_rounded, onTap: () => session.seek(pos - const Duration(seconds: 10))),
                  const SizedBox(width: 26),
                  _RoundBtn(
                    big: true,
                    icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onTap: session.playOrPause,
                  ),
                  const SizedBox(width: 26),
                  _RoundBtn(icon: Icons.forward_10_rounded, onTap: () => session.seek(pos + const Duration(seconds: 10))),
                ],
              ),

              const Spacer(),

              // ── Bottom: seek bar + meta row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SeekBar(
                  position: pos,
                  duration: dur,
                  buffered: bufferedAhead,
                  onSeek: (d) => session.seek(d),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${Fmt.clock(pos)} / ${Fmt.clock(session.duration)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    _TopPill(
                      icon: Icons.speed_rounded,
                      label: '${session.player.state.rate}×',
                      onTap: _cycleSpeed,
                    ),
                    const SizedBox(width: 8),
                    _TopPill(
                      icon: Icons.high_quality_rounded,
                      label: session.abr.locked?.label ?? 'Auto',
                      onTap: () => showQualitySheet(
                        context,
                        session: session,
                        telemetry: session.telemetry,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cycleSpeed() async {
    final session = widget.app.session;
    const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    final cur = session.player.state.rate;
    final next = speeds.firstWhere((s) => s > cur + 0.01, orElse: () => 0.75);
    await session.setRate(next);
    _bumpControls();
  }

  // ---------------------------------------------------------------- lab

  Widget _buildLab(BuildContext context, StreamSession session) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width >= 760 ? 390 : double.infinity,
        margin: const EdgeInsets.all(0),
        color: Colors.black.withOpacity(.92),
        child: StreamLab(
          session: session,
          telemetry: session.telemetry,
          onClose: () => setState(() => _labOpen = false),
        ),
      ),
    );
  }
}

// ==================================================================
// Pieces
// ==================================================================

class _LoadingPane extends StatelessWidget {
  final StreamSession session;
  final Movie movie;
  const _LoadingPane({required this.session, required this.movie});

  @override
  Widget build(BuildContext context) {
    final events = session.telemetry.events.take(3).toList();
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2.4),
            const SizedBox(height: 18),
            Text('Warming up "${movie.title}"',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            Text('probing CDNs · seeding bandwidth · preloading manifest',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 18),
            for (final e in events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '› ${e.message}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.cyan, fontSize: 10.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TopPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.cyan),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool big;
  const _RoundBtn({required this.icon, required this.onTap, this.big = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: big ? 72 : 52,
        height: big ? 72 : 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: big ? 38 : 26),
      ),
    );
  }
}

/// YouTube-grade seek bar: played / buffered / remaining, draggable thumb.
class _SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final void Function(Duration) onSeek;
  const _SeekBar({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.onSeek,
  });

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragFrac;

  @override
  Widget build(BuildContext context) {
    final posFrac = _dragFrac ??
        (widget.duration.inMilliseconds == 0
            ? 0.0
            : (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0).toDouble());
    final bufFrac = widget.duration.inMilliseconds == 0
        ? 0.0
        : (widget.buffered.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0).toDouble();

    void seekTo(double frac) {
      widget.onSeek(Duration(milliseconds: (widget.duration.inMilliseconds * frac).round()));
    }

    double fracOf(Offset local) =>
        (local.dx / (MediaQuery.of(context).size.width - 32)).clamp(0.0, 1.0).toDouble();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        seekTo(fracOf(d.localPosition));
      },
      onHorizontalDragStart: (d) => setState(() => _dragFrac = fracOf(d.localPosition)),
      onHorizontalDragUpdate: (d) => setState(() => _dragFrac = fracOf(d.localPosition)),
      onHorizontalDragEnd: (_) {
        if (_dragFrac != null) seekTo(_dragFrac!);
        setState(() => _dragFrac = null);
      },
      child: SizedBox(
        height: 30,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: bufFrac,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.38),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: posFrac,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.violet]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: ((MediaQuery.of(context).size.width - 32) * posFrac - 7).toDouble(),
                top: -5,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppTheme.cyan.withOpacity(.7), blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated ripple on double-tap seek.
class _SeekRipple extends StatelessWidget {
  final int side;
  const _SeekRipple({required this.side});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: side < 0 ? 0 : null,
      right: side > 0 ? 0 : null,
      width: MediaQuery.of(context).size.width / 2,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              side < 0 ? Icons.replay_10_rounded : Icons.forward_10_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
