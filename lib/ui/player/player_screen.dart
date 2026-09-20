import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../engine/stream_session.dart';
import '../widgets/aurora_bg.dart';
import 'quality_sheet.dart';
import 'stream_lab.dart';

/// The player v2: mpv-grade playback (media_kit) under a fully custom
/// CineFlux control layer — aurora seek bar with scrub bubble, ±10s
/// double-tap seek with animated ripple, speed control, quality ladder,
/// and the Stream Lab telemetry overlay. Controls fade and slide away.
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

              // ── Controls overlay (animated) ──
              if (started)
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: _buildControls(context, session),
                  ),
                ),

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
    await Future<void>.delayed(const Duration(milliseconds: 460));
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
    final bufferedAhead = session.buffered > pos ? session.buffered : pos;
    final playing = session.player.state.playing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _bumpControls,
      child: Container(
        color: Colors.black.withOpacity(.24),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    _GlassCircle(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_movie.isSeries ? _movie.seriesLabel : _movie.year}  ·  ${Uri.parse(session.activeUrl).host}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 10.5, letterSpacing: .4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GlassPill(
                      icon: Icons.auto_awesome_rounded,
                      label: 'STREAM LAB',
                      dot: true,
                      onTap: () => setState(() => _labOpen = true),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Center cluster ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SeekBtn(icon: Icons.replay_10_rounded, onTap: () => session.seek(pos - const Duration(seconds: 10))),
                  const SizedBox(width: 30),
                  _PlayButton(playing: playing, onTap: session.playOrPause),
                  const SizedBox(width: 30),
                  _SeekBtn(icon: Icons.forward_10_rounded, onTap: () => session.seek(pos + const Duration(seconds: 10))),
                ],
              ),

              const Spacer(),

              // ── Bottom: seek bar + meta row ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SeekBar(
                  position: pos,
                  duration: session.duration,
                  buffered: bufferedAhead,
                  onSeek: (d) => session.seek(d),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${Fmt.clock(pos)}  /  ${Fmt.clock(session.duration)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (session.buffering) ...[
                      const SizedBox(width: 10),
                      const _BufferingHint(),
                    ],
                    const Spacer(),
                    _GlassPill(
                      icon: Icons.speed_rounded,
                      label: '${session.player.state.rate}×',
                      onTap: _cycleSpeed,
                    ),
                    const SizedBox(width: 8),
                    _GlassPill(
                      icon: Icons.high_quality_rounded,
                      label: session.abr.locked?.label ?? 'AUTO',
                      onTap: () => showQualitySheet(
                        context,
                        session: session,
                        telemetry: session.telemetry,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
        width: MediaQuery.of(context).size.width >= 760 ? 392 : double.infinity,
        color: Colors.black.withOpacity(.94),
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

/// Cinematic warm-up pane: aurora spinner, live engine phase feed.
class _LoadingPane extends StatelessWidget {
  final StreamSession session;
  final Movie movie;
  const _LoadingPane({required this.session, required this.movie});

  @override
  Widget build(BuildContext context) {
    final events = session.telemetry.events.take(3).toList();
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          const Positioned.fill(child: AuroraBackdrop(intensity: 1.4)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuroraSpinner(size: 52),
                const SizedBox(height: 22),
                Text(
                  'Warming up "${movie.title}"',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: -.2),
                ),
                const SizedBox(height: 7),
                Text(
                  'probing CDNs · seeding bandwidth · preloading manifest',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 22),
                for (final e in events)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.05),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white.withOpacity(.07)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(color: AppTheme.cyan, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.message,
                          style: const TextStyle(color: AppTheme.cyan, fontSize: 10.5),
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
  }
}

/// Circular glass button (back, etc.).
class _GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(.1),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

/// Glass pill for top/bottom control rows.
class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dot;
  const _GlassPill({required this.icon, required this.label, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              const PulseDot(color: AppTheme.cyan, size: 5),
              const SizedBox(width: 6),
            ],
            Icon(icon, size: 13, color: AppTheme.cyan),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeekBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SeekBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }
}

/// Aurora play button — gradient ring, dark core, glow.
class _PlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  const _PlayButton({required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: AppTheme.aurora,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppTheme.indigo.withOpacity(.55), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          alignment: Alignment.center,
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _BufferingHint extends StatelessWidget {
  const _BufferingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.amber.withOpacity(.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.amber.withOpacity(.4)),
      ),
      child: const Text(
        'BUFFERING',
        style: TextStyle(color: AppTheme.amber, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
    );
  }
}

/// Aurora seek bar v2 — LayoutBuilder-precise hit testing, played /
/// buffered / remaining, draggable thumb with a floating time bubble.
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
    final durMs = widget.duration.inMilliseconds;
    final posFrac = _dragFrac ?? (durMs == 0 ? 0.0 : (widget.position.inMilliseconds / durMs).clamp(0.0, 1.0).toDouble());
    final bufFrac = durMs == 0 ? 0.0 : (widget.buffered.inMilliseconds / durMs).clamp(0.0, 1.0).toDouble();

    void seekTo(double frac) {
      widget.onSeek(Duration(milliseconds: (durMs * frac).round()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        double fracOf(Offset local) => (local.dx / w).clamp(0.0, 1.0).toDouble();
        final thumbX = w * posFrac;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => seekTo(fracOf(d.localPosition)),
          onHorizontalDragStart: (d) => setState(() => _dragFrac = fracOf(d.localPosition)),
          onHorizontalDragUpdate: (d) => setState(() => _dragFrac = fracOf(d.localPosition)),
          onHorizontalDragEnd: (_) {
            if (_dragFrac != null) seekTo(_dragFrac!);
            setState(() => _dragFrac = null);
          },
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // Scrub time bubble.
                if (_dragFrac != null)
                  Positioned(
                    left: (thumbX - 34).clamp(0.0, w - 68).toDouble(),
                    top: -6,
                    child: Container(
                      width: 68,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: AppTheme.cyan.withOpacity(.4), blurRadius: 14),
                        ],
                      ),
                      child: Text(
                        Fmt.clock(Duration(milliseconds: (durMs * _dragFrac!).round())),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                // Track.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _dragFrac != null ? 0 : 7),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.16),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: bufFrac,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.34),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: posFrac,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(colors: AppTheme.aurora),
                            boxShadow: [
                              BoxShadow(color: AppTheme.cyan.withOpacity(.65), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Thumb.
                Positioned(
                  left: thumbX - 7,
                  top: 13,
                  child: AnimatedScale(
                    scale: _dragFrac != null ? 1.35 : 1,
                    duration: const Duration(milliseconds: 140),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.cyan, width: 1.6),
                        boxShadow: [
                          BoxShadow(color: AppTheme.cyan.withOpacity(.75), blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated ripple on double-tap seek — expands + fades.
class _SeekRipple extends StatefulWidget {
  final int side;
  const _SeekRipple({required this.side});

  @override
  State<_SeekRipple> createState() => _SeekRippleState();
}

class _SeekRippleState extends State<_SeekRipple> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: widget.side < 0 ? 0 : null,
      right: widget.side > 0 ? 0 : null,
      width: MediaQuery.of(context).size.width / 2,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_c.value);
              return Opacity(
                opacity: (1 - t) * .9,
                child: Transform.scale(
                  scale: .55 + .55 * t,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                widget.side < 0 ? Icons.replay_10_rounded : Icons.forward_10_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
