import 'package:flutter/foundation.dart';

import '../data/catalog.dart';
import '../data/library_repo.dart';
import '../data/models.dart';
import '../engine/stream_session.dart';

/// App-wide state: the streaming session, my-list, continue-watching map.
class AppState extends ChangeNotifier {
  final LibraryRepo repo = LibraryRepo.I;

  /// One persistent streaming session for the whole app.
  final StreamSession session = StreamSession();

  Map<String, double> progress = {};
  Set<String> myList = {};

  AppState() {
    refresh();
  }

  Future<void> refresh() async {
    progress = await repo.allProgress();
    myList = await repo.myList();
    notifyListeners();
  }

  double progressOf(Movie m) => progress[m.id] ?? 0;

  List<Movie> continueWatching() {
    final ids = progress.keys.where((k) {
      final v = progress[k] ?? 0;
      return v > 0.01 && v < 0.95;
    }).toList();
    final movies = ids.map(Catalog.byId).toList();
    return movies;
  }

  List<Movie> myListMovies() => myList.map(Catalog.byId).toList();

  Future<void> toggleMyList(String id) async {
    await repo.toggleMyList(id);
    myList = await repo.myList();
    notifyListeners();
  }

  bool inMyList(String id) => myList.contains(id);

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }
}
