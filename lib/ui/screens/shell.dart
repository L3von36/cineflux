import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../widgets/aurora_bg.dart';
import 'home.dart';
import 'mylist.dart';
import 'search.dart';

/// Adaptive shell v2 — a floating glass navigation bar on phones, a lit
/// aurora rail on wide screens, with the ambient aurora wash behind the
/// whole app. Same destinations, native feel everywhere.
class Shell extends StatefulWidget {
  final AppState app;
  const Shell({super.key, required this.app});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'CineFlux',
      applicationVersion: '2.0 · Aurora',
      applicationIcon: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppTheme.aurora,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
      ),
      children: const [
        Text(
          'A cinematic streaming experience engineered with the same magic as '
          'the giants — adaptive bitrate, multi-CDN failover, buffer-aware '
          'quality switching, preload pipelines and live Stream Lab telemetry.',
          style: TextStyle(fontSize: 13, height: 1.55, color: AppTheme.textMid),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    final body = AnimatedBuilder(
      animation: widget.app,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        child: switch (_tab) {
          0 => HomeScreen(app: widget.app, key: const ValueKey('home')),
          1 => SearchScreen(app: widget.app, key: const ValueKey('search')),
          _ => MyListScreen(app: widget.app, key: const ValueKey('list'), onBrowse: _goHome),
        },
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Ambient aurora wash — the theater light behind everything.
          const Positioned.fill(child: AuroraBackdrop()),
          Row(
            children: [
              if (wide) _AuroraRail(tab: _tab, onGo: _go, onAbout: _showAbout),
              Expanded(
                child: Column(
                  children: [
                    if (!wide) _MobileHeader(onAbout: _showAbout),
                    Expanded(child: body),
                    if (!wide) const SizedBox(height: 76),
                  ],
                ),
              ),
            ],
          ),
          // Floating glass nav bar above the aurora wash.
          if (!wide)
            Align(
              alignment: Alignment.bottomCenter,
              child: AuroraNavBar(tab: _tab, onGo: _go),
            ),
        ],
      ),
    );
  }

  void _goHome() => _go(0);
}

// ── Mobile header ─────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  final VoidCallback onAbout;
  const _MobileHeader({required this.onAbout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Row(
          children: [
            const CineFluxLogo(),
            const Spacer(),
            GestureDetector(
              onTap: onAbout,
              child: Tooltip(
                message: 'About CineFlux',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppTheme.aurora,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: AppTheme.indigo.withOpacity(.35), blurRadius: 14),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surface,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person_rounded, size: 19, color: AppTheme.textHi),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wide-screen rail ──────────────────────────────────────────────────────

class _AuroraRail extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onGo;
  final VoidCallback onAbout;
  const _AuroraRail({required this.tab, required this.onGo, required this.onAbout});

  static const _items = [
    (icon: Icons.movie_filter_outlined, active: Icons.movie_filter_rounded, label: 'Home'),
    (icon: Icons.search_outlined, active: Icons.search_rounded, label: 'Search'),
    (icon: Icons.bookmark_border_rounded, active: Icons.bookmark_rounded, label: 'My List'),
  ];

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(.72),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(.05))),
      ),
      child: Column(
        children: [
          SizedBox(height: topInset + 24),
          const CineFluxLogo(vertical: true),
          const SizedBox(height: 26),
          for (var i = 0; i < _items.length; i++)
            _RailItem(
              item: _items[i],
              active: tab == i,
              onTap: () => onGo(i),
            ),
          const Spacer(),
          GestureDetector(
            onTap: onAbout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(.08)),
                color: AppTheme.surfaceHi.withOpacity(.5),
              ),
              child: const Text(
                'v2.0',
                style: TextStyle(color: AppTheme.textDim, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final ({IconData icon, IconData active, String label}) item;
  final bool active;
  final VoidCallback onTap;
  const _RailItem({required this.item, required this.active, required this.onTap});

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;
  bool get _lit => widget.active || _hover;

  @override
  Widget build(BuildContext context) {
    final d = widget.item;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedOpacity(
            opacity: _lit ? 1 : .62,
            duration: const Duration(milliseconds: 180),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: widget.active
                        ? LinearGradient(
                            colors: [
                              AppTheme.cyan.withOpacity(.22),
                              AppTheme.violet.withOpacity(.22),
                            ],
                          )
                        : _hover
                            ? LinearGradient(colors: [AppTheme.surfaceHi, AppTheme.surfaceHi])
                            : null,
                    border: Border.all(
                      color: widget.active
                          ? AppTheme.cyan.withOpacity(.45)
                          : Colors.white.withOpacity(.05),
                    ),
                    boxShadow: widget.active
                        ? [BoxShadow(color: AppTheme.indigo.withOpacity(.25), blurRadius: 16)]
                        : null,
                  ),
                  child: Icon(
                    widget.active ? d.active : d.icon,
                    size: 23,
                    color: widget.active ? AppTheme.cyan : AppTheme.textMid,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
                    color: widget.active ? AppTheme.textHi : AppTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating glass bottom bar ─────────────────────────────────────────────

class AuroraNavBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onGo;
  const AuroraNavBar({super.key, required this.tab, required this.onGo});

  static const _items = [
    (icon: Icons.movie_filter_outlined, active: Icons.movie_filter_rounded, label: 'Home'),
    (icon: Icons.search_outlined, active: Icons.search_rounded, label: 'Search'),
    (icon: Icons.bookmark_border_rounded, active: Icons.bookmark_rounded, label: 'My List'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.07)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.55), blurRadius: 26, offset: const Offset(0, 10)),
            BoxShadow(color: AppTheme.indigo.withOpacity(.10), blurRadius: 34),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _BarItem(
                  item: _items[i],
                  active: tab == i,
                  onTap: () => onGo(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final ({IconData icon, IconData active, String label}) item;
  final bool active;
  final VoidCallback onTap;
  const _BarItem({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = item;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: active
                ? const LinearGradient(colors: AppTheme.aurora)
                : const LinearGradient(colors: [Colors.transparent, Colors.transparent]),
            boxShadow: active
                ? [BoxShadow(color: AppTheme.indigo.withOpacity(.4), blurRadius: 18)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.06 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(
                  active ? d.active : d.icon,
                  size: 21,
                  color: active ? Colors.black : AppTheme.textMid,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(
                          d.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────

class CineFluxLogo extends StatelessWidget {
  final bool vertical;
  const CineFluxLogo({super.key, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: vertical ? 42 : 36,
      height: vertical ? 42 : 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.aurora,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(vertical ? 13 : 11),
        boxShadow: [
          BoxShadow(color: AppTheme.indigo.withOpacity(.45), blurRadius: 18),
        ],
      ),
      child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: vertical ? 27 : 24),
    );

    final word = ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        colors: AppTheme.aurora,
      ).createShader(r),
      child: Text(
        'CINEFLUX',
        style: TextStyle(
          fontSize: vertical ? 15 : 17.5,
          fontWeight: FontWeight.w900,
          letterSpacing: vertical ? 3.4 : 4.4,
          color: Colors.white,
        ),
      ),
    );

    if (vertical) {
      return Column(
        children: [
          mark,
          const SizedBox(height: 10),
          word,
          const SizedBox(height: 6),
          Container(
            width: 26,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(colors: AppTheme.aurora),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        mark,
        const SizedBox(width: 11),
        word,
      ],
    );
  }
}
