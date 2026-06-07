import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFFFCF9F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textMuted = Color(0xFF8E8E8E);
  static const Color textLight = Color(0xFFBFBFBF);
  static const Color accent = Color(0xFFCD9B6E);
  static const Color accentLight = Color(0xFFF5EDE4);
  static const Color accentBg = Color(0xFFFFF8F0);
  static const Color highlight = Color(0xFF5B8C7E);
  static const Color highlightLight = Color(0xFFE8F5F0);
  static const Color danger = Color(0xFFD4756B);

  static const double radiusSm = 12;
  static const double radiusMd = 18;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: highlight,
        surface: card,
        onSurface: textDark,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
