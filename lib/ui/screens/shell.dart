import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import 'home.dart';
import 'mylist.dart';
import 'search.dart';

/// Adaptive shell: NavigationRail on wide screens (desktop/web landscape),
/// NavigationBar on phones. Same destinations, native feel everywhere.
class Shell extends StatefulWidget {
  final AppState app;
  const Shell({super.key, required this.app});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    final body = AnimatedBuilder(
      animation: widget.app,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        child: switch (_tab) {
          0 => HomeScreen(app: widget.app, key: const ValueKey('home')),
          1 => SearchScreen(app: widget.app, key: const ValueKey('search')),
          _ => MyListScreen(app: widget.app, key: const ValueKey('list')),
        },
      ),
    );

    final destinations = const [
      (icon: Icons.movie_creation_outlined, active: Icons.movie_creation, label: 'Home'),
      (icon: Icons.search_outlined, active: Icons.search, label: 'Search'),
      (icon: Icons.bookmark_border_rounded, active: Icons.bookmark_rounded, label: 'My List'),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            Container(
              width: 96,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(right: BorderSide(color: AppTheme.line)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  const _Logo(vertical: true),
                  const SizedBox(height: 18),
                  Expanded(
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIndex: _tab,
                      onDestinationSelected: (i) => setState(() => _tab = i),
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.4,
                      destinations: [
                        for (final d in destinations)
                          NavigationRailDestination(
                            icon: Icon(d.icon, size: 22),
                            selectedIcon: Icon(d.active, size: 22),
                            label: Text(d.label, style: const TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Text('v1.0', style: TextStyle(color: AppTheme.textMid, fontSize: 10)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (!wide) const _MobileAppBar(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.active),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}

class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 52, 20, 6),
      child: _Logo(),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool vertical;
  const _Logo({this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final word = ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        colors: [AppTheme.cyan, AppTheme.violet],
      ).createShader(r),
      child: const Text(
        'CINEFLUX',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.5,
          color: Colors.white,
        ),
      ),
    );
    if (vertical) {
      return Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.violet]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
          ),
          const SizedBox(height: 8),
          word,
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.violet]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
        ),
        const SizedBox(width: 10),
        word,
      ],
    );
  }
}
