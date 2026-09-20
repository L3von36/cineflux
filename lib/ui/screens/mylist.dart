import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../widgets/movie_card.dart';
import 'detail.dart';

class MyListScreen extends StatelessWidget {
  final AppState app;
  const MyListScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final items = app.myListMovies();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line),
              ),
              child: const Icon(Icons.bookmark_border_rounded, size: 34, color: AppTheme.textMid),
            ),
            const SizedBox(height: 16),
            const Text('Nothing saved yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'Tap the bookmark on any title and it will be waiting for you here — on every device you sign into.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMid, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
        return MovieCard(
          movie: m,
          width: double.infinity,
          progress: app.progressOf(m),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DetailScreen(movie: m, app: app),
          )),
        );
      },
    );
  }
}
