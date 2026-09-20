import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/movie_card.dart';
import 'detail.dart';

class SearchScreen extends StatefulWidget {
  final AppState app;
  const SearchScreen({super.key, required this.app});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _q = '';
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = Catalog.search(_q);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // ── Aurora search field ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _focused ? AppTheme.cyan.withOpacity(.7) : Colors.white.withOpacity(.07),
                width: _focused ? 1.3 : 1,
              ),
              boxShadow: _focused
                  ? [BoxShadow(color: AppTheme.cyan.withOpacity(.14), blurRadius: 22)]
                  : [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: TextField(
              focusNode: _focus,
              onChanged: (v) => setState(() => _q = v),
              style: const TextStyle(fontSize: 15),
              cursorColor: AppTheme.cyan,
              decoration: InputDecoration(
                hintText: 'Search titles, genres, cast…',
                hintStyle: const TextStyle(color: AppTheme.textDim),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _focused ? AppTheme.cyan : AppTheme.textDim,
                ),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textDim),
                        onPressed: () {
                          _focus.unfocus();
                          setState(() => _q = '');
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_q.isEmpty) ...[
            Row(
              children: [
                _tick(),
                const Text('Browse by genre', style: AppTheme.sectionTitle),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in Catalog.genres())
                  GestureDetector(
                    onTap: () => setState(() => _q = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHi.withOpacity(.7),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white.withOpacity(.07)),
                      ),
                      child: Text(
                        g,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textMid, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Expanded(
            child: results.isEmpty && _q.isNotEmpty
                ? _EmptyState(query: _q, onClear: () => setState(() => _q = ''))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tick(),
                          Text(
                            _q.isEmpty
                                ? 'All titles'
                                : '${results.length} result${results.length == 1 ? '' : 's'} for "$_q"',
                            style: AppTheme.sectionTitle.copyWith(fontSize: 15.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 160,
                            childAspectRatio: 2 / 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final m = results[i];
                            return _GridStagger(
                              index: i,
                              child: MovieCard(
                                movie: m,
                                width: double.infinity,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => DetailScreen(movie: m, app: widget.app),
                                )),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tick() => Container(
        width: 4,
        height: 14,
        margin: const EdgeInsets.only(right: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: AppTheme.aurora,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
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

class _EmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;
  const _EmptyState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aurora halo.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.cyan.withOpacity(.16),
                AppTheme.violet.withOpacity(.07),
                Colors.transparent,
              ]),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: Colors.white.withOpacity(.08)),
              ),
              child: const Icon(Icons.search_rounded, size: 26, color: AppTheme.textDim),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No matches for "$query"',
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Try a different title, genre or cast member — the catalog also matches partial words.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDim, fontSize: 12.5, height: 1.55),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}
