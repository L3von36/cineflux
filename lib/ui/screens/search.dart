import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
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

  @override
  Widget build(BuildContext context) {
    final results = Catalog.search(_q);
    final suggestions = _q.isEmpty ? Catalog.all : results;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search titles, genres, cast…',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMid),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.cyan, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_q.isEmpty) ...[
            const Text('Browse by genre', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in Catalog.genres())
                  ActionChip(
                    label: Text(g),
                    backgroundColor: AppTheme.surfaceHi,
                    side: const BorderSide(color: AppTheme.line),
                    onPressed: () => setState(() => _q = g),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Text(
            _q.isEmpty
                ? 'All titles'
                : results.isEmpty
                    ? 'No matches for "$_q"'
                    : '${results.length} result${results.length == 1 ? '' : 's'} for "$_q"',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final m = suggestions[i];
                return MovieCard(
                  movie: m,
                  width: double.infinity,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DetailScreen(movie: m, app: widget.app),
                  )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
