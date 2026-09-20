import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'ui/screens/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // mpv bindings for every platform (Android, iOS, web, Windows, macOS, Linux).
  MediaKit.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CineFluxApp());
}

class CineFluxApp extends StatefulWidget {
  const CineFluxApp({super.key});

  @override
  State<CineFluxApp> createState() => _CineFluxAppState();
}

class _CineFluxAppState extends State<CineFluxApp> {
  late final AppState app = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableProvider(
      notifier: app,
      child: MaterialApp(
        title: 'CineFlux',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: Shell(app: app),
      ),
    );
  }

  @override
  void dispose() {
    app.dispose();
    super.dispose();
  }
}

/// Minimal inherited provider — keeps dependencies light and the build fast.
class ListenableProvider extends InheritedNotifier<AppState> {
  const ListenableProvider({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<ListenableProvider>();
    assert(inherited != null, 'ListenableProvider not found in tree');
    return inherited!.notifier!;
  }
}
