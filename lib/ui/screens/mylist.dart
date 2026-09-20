import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/movie_card.dart';
import 'detail.dart';

class MyListScreen extends StatelessWidget {
  final AppState app;
  final VoidCallback? onBrowse;
  const MyListScreen({super.key, required this.app, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final items = app.myListMovies();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StaggerIn(
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.violet.withOpacity(.18),
                    AppTheme.cyan.withOpacity(.08),
                    Colors.transparent,
                  ]),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surface,
                    border: Border.all(color: Colors.white.withOpacity(.09)),
                    boxShadow: [
                      BoxShadow(color: AppTheme.indigo.withOpacity(.2), blurRadius: 22),
                    ],
                  ),
                  child: const Icon(Icons.bookmark_border_rounded, size: 30, color: AppTheme.textMid),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const StaggerIn(
              index: 1,
              child: Text('Nothing saved yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.3)),
            ),
            const SizedBox(height: 8),
            const StaggerIn(
              index: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 56),
                child: Text(
                  'Tap the bookmark on any title and it will be waiting for you here — synced on every device you sign into.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDim, fontSize: 12.5, height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            StaggerIn(
              index: 3,
              child: FilledButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.movie_filter_rounded, size: 19),
                label: const Text('Browse titles'),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final m = items[i];
        return _GridStagger(
          index: i,
          child: MovieCard(
            movie: m,
            width: double.infinity,
            progress: app.progressOf(m),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DetailScreen(movie: m, app: app),
            )),
          ),
        );
      },
    );
  }
}

class _GridStagger extends StatefulWidget {
  final int index;
  final Widget child;
  const _GridStagger({required this.index, required this.child});

  @override
  State<_GridStagger> createState() => _GridStaggerState();
}

class _GridStaggerState extends State<_GridStagger> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 + 40 * widget.index.clamp(0, 10)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
