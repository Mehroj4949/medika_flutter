import 'package:flutter/material.dart';

class MedikaColors {
  static const navy = Color(0xFF07172F);
  static const navy2 = Color(0xFF0B2D63);
  static const blue = Color(0xFF1762F2);
  static const softBlue = Color(0xFFEDF3FF);
  static const background = Color(0xFFF5F7FB);
  static const line = Color(0xFFE5EAF2);
  static const muted = Color(0xFF778399);
}

ThemeData buildMedikaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MedikaColors.blue,
    brightness: Brightness.light,
  ).copyWith(
    primary: MedikaColors.blue,
    secondary: MedikaColors.navy,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MedikaColors.background,
    fontFamily: 'Arial',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: MedikaColors.navy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: MedikaColors.line),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: MedikaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: MedikaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: MedikaColors.blue, width: 1.4),
      ),
    ),
  );
}
