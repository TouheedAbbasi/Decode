import 'package:flutter/material.dart';

/// Decode design tokens: ultra-minimal, charcoal + indigo.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final bg = dark ? const Color(0xFF0E1015) : const Color(0xFFFAFAF8);
    final surface = dark ? const Color(0xFF161922) : const Color(0xFFFFFFFF);
    final border = dark ? const Color(0xFF262A36) : const Color(0xFFE6E6E1);
    final text = dark ? const Color(0xFFE9EAEF) : const Color(0xFF1B1C20);
    final muted = dark ? const Color(0xFF8D93A5) : const Color(0xFF6B6F7B);
    final accent = dark ? const Color(0xFF7168F7) : const Color(0xFF4F46E5);
    final accentSoft = dark ? const Color(0xFF23254A) : const Color(0xFFEEEDFC);

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      primaryContainer: accentSoft,
      onPrimaryContainer: accent,
    );

    final radius = BorderRadius.circular(10);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentSoft,
        height: 66,
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
