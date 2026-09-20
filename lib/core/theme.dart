import 'package:flutter/material.dart';

/// ── CINEFLUX AURORA — design system v2 ──────────────────────────────────
/// A deeper, richer cinematic surface system: obsidian blues, a three-stop
/// aurora accent (cyan → indigo → fuchsia), glassy lit panels, gradient
/// hairlines and glow accents. Everything is generated locally so the app
/// paints beautifully with zero network — instant cold start.
class AppTheme {
  // ── Base layers ──
  static const Color bg = Color(0xFF05060B);
  static const Color bgHi = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF0D1220);
  static const Color surfaceHi = Color(0xFF151C30);
  static const Color line = Color(0xFF222C46);
  static const Color textHi = Color(0xFFF4F6FF);
  static const Color textMid = Color(0xFF97A3BC);
  static const Color textDim = Color(0xFF5C6880);

  // ── Aurora accents ──
  static const Color cyan = Color(0xFF2DD9FE);
  static const Color indigo = Color(0xFF818CF8);
  static const Color violet = Color(0xFFD26BFA);
  static const Color amber = Color(0xFFFFC24B);
  static const Color green = Color(0xFF3DDC97);
  static const Color red = Color(0xFFFF6B7A);

  /// The signature three-stop aurora gradient.
  static const List<Color> aurora = [cyan, indigo, violet];
  static const LinearGradient auroraGradient = LinearGradient(colors: aurora);

  /// Radial aurora used by glass panels and hero washes.
  static const LinearGradient auroraFaded = LinearGradient(
    colors: [Color(0x332DD9FE), Color(0x2E818CF8), Color(0x2ED26BFA)],
  );

  // ── Type helpers ──
  static const TextStyle kicker = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.6,
    color: textDim,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17.5,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: textHi,
  );

  static TextStyle body(BuildContext context) =>
      const TextStyle(fontSize: 14.5, height: 1.6, color: Color(0xFFC7D0E2));

  /// Glass panel decoration — the "lit from within" CineFlux surface.
  static BoxDecoration glass({double radius = 16, Color? fill, BorderRadius? br}) {
    return BoxDecoration(
      color: fill ?? surface,
      borderRadius: br ?? BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(.055)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8)),
      ],
    );
  }

  /// Aurora gradient border via outer/inner shell trick.
  static Widget auroraBorder({required Widget child, double radius = 16, double opacity = .5}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 1.2),
        gradient: LinearGradient(
          colors: [cyan.withOpacity(opacity), indigo.withOpacity(opacity), violet.withOpacity(opacity)],
        ),
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      primary: cyan,
      secondary: violet,
      surface: surface,
      error: red,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textHi,
        displayColor: textHi,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHi,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(color: textMid, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: textHi,
          foregroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textHi,
          side: BorderSide(color: Colors.white.withOpacity(.16)),
          backgroundColor: Colors.white.withOpacity(.06),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHi,
        contentTextStyle: const TextStyle(color: textHi),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: textHi,
        unselectedLabelColor: textMid,
        indicatorColor: cyan,
        dividerColor: line,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: cyan,
        linearTrackColor: surfaceHi,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
