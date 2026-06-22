// Theme system — three full styles: classic, modern, elder.
import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../models/reading.dart';

class AppTheme {
  static ThemeData forStyle(ThemeStyle style, {bool isDark = false}) {
    switch (style) {
      case ThemeStyle.classic:
        return _classic(isDark);
      case ThemeStyle.modern:
        return _modern(isDark);
      case ThemeStyle.elder:
        return _elder(isDark);
    }
  }

  // ===== Classic Medical =====
  static ThemeData _classic(bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    const teal = Color(0xFF0D9488);
    const emerald = Color(0xFF059669);
    return base.copyWith(
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Color(0xFF14B8A6),
              secondary: Color(0xFF34D399),
              surface: Color(0xFF1E293B),
            )
          : const ColorScheme.light(
              primary: teal,
              secondary: emerald,
              surface: Colors.white,
            ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : const Color(0xFF334155),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : const Color(0xFF475569),
        ),
      ),
    );
  }

  // ===== Modern Youth (dark by default) =====
  static ThemeData _modern(bool isDark) {
    final base = ThemeData.dark();
    const fuchsia = Color(0xFFD946EF);
    const cyan = Color(0xFF22D3EE);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: fuchsia,
        surface: Color(0xFF1A1F2E),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      cardColor: const Color(0xFF1A1F2E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1F2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fuchsia,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: const TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }

  // ===== Elder Friendly =====
  static ThemeData _elder(bool isDark) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    const slate = Color(0xFF0F172A);
    return base.copyWith(
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Colors.white,
              secondary: slate,
              surface: slate,
            )
          : const ColorScheme.light(
              primary: slate,
              secondary: slate,
              surface: Color(0xFFF8FAFC),
            ),
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      cardColor: isDark ? slate : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? slate : Colors.white,
        foregroundColor: isDark ? Colors.white : slate,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? slate : const Color(0xFFF8FAFC),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: slate, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: slate, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: slate, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: slate,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF334155),
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          color: isDark ? Colors.white70 : const Color(0xFF475569),
        ),
      ),
    );
  }
}

// Status color helper (shared across all themes)
Color statusColor(ReadingStatus s) {
  switch (s) {
    case ReadingStatus.low:
    case ReadingStatus.criticalLow:
      return const Color(0xFFF59E0B);
    case ReadingStatus.inRange:
      return const Color(0xFF10B981);
    case ReadingStatus.high:
    case ReadingStatus.criticalHigh:
      return const Color(0xFFEF4444);
  }
}
