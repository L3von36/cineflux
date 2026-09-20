import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: watch progress (resume), my-list, settings.
/// Keys are namespaced and JSON-encoded for forward compatibility.
class LibraryRepo {
  LibraryRepo._();
  static final LibraryRepo I = LibraryRepo._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ---------- watch progress ----------
  static const _progressKey = 'cineflux.progress.v1';

  Future<Map<String, double>> _loadProgress() async {
    final p = await _p;
    final raw = p.getString(_progressKey);
    if (raw == null) return {};
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  /// Returns playback fraction (0..1) for a title, or 0.
  Future<double> progressOf(String id) async {
    final m = await _loadProgress();
    return m[id] ?? 0;
  }

  /// Progress for every title that has one — powers "Continue Watching".
  Future<Map<String, double>> allProgress() => _loadProgress();

  Future<void> saveProgress(String id, double fraction) async {
    final p = await _p;
    final m = await _loadProgress();
    if (fraction >= 0.98) {
      m.remove(id); // finished — don't nag the user
    } else if (fraction > 0.01) {
      m[id] = fraction;
    }
    await p.setString(_progressKey, jsonEncode(m));
  }

  // ---------- my list ----------
  static const _listKey = 'cineflux.mylist.v1';

  Future<Set<String>> myList() async {
    final p = await _p;
    return (p.getStringList(_listKey) ?? const []).toSet();
  }

  Future<bool> toggleMyList(String id) async {
    final p = await _p;
    final set = await myList();
    final added = !set.contains(id);
    added ? set.add(id) : set.remove(id);
    await p.setStringList(_listKey, set.toList());
    return added;
  }

  // ---------- settings ----------
  Future<void> setDataSaver(bool on) async {
    final p = await _p;
    await p.setBool('cineflux.datasaver', on);
  }

  Future<bool> dataSaver() async => (await _p).getBool('cineflux.datasaver') ?? false;

  Future<void> setAutoplayNext(bool on) async {
    final p = await _p;
    await p.setBool('cineflux.autoplay', on);
  }

  Future<bool> autoplayNext() async => (await _p).getBool('cineflux.autoplay') ?? true;
}
