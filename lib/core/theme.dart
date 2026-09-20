import 'package:flutter/material.dart';

/// CineFlux cinematic design system — Material 3.
///
/// Deep-space blacks, electric cyan + violet accents, glassy surfaces.
/// Everything is generated locally (gradients, glow, grain) so the app
/// paints beautifully even with zero network — instant cold start.
class AppTheme {
  // Palette anchors.
  static const Color bg = Color(0xFF07090F);
  static const Color surface = Color(0xFF0D1118);
  static const Color surfaceHi = Color(0xFF151B26);
  static const Color line = Color(0xFF1E2633);
  static const Color textHi = Color(0xFFF2F5FA);
  static const Color textMid = Color(0xFF9AA6B8);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFFFB454);
  static const Color green = Color(0xFF34D399);
  static const Color red = Color(0xFFF87171);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: cyan.withOpacity(.14),
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHi,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(color: textMid, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: textHi,
          foregroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textHi,
          side: const BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
    );
  }
}
