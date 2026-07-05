import 'package:flutter/material.dart';

abstract final class SimaColors {
  static const navy = Color(0xFF092444);
  static const navyDeep = Color(0xFF062E4F);
  static const green = Color(0xFF39A900);
  static const greenDark = Color(0xFF2B8500);
  static const cyan = Color(0xFF00A4E4);
  static const background = Color(0xFFF2F5FB);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFF7FAFE);
  static const textMuted = Color(0xFF607086);
  static const textSoft = Color(0xFF8A96A6);
  static const border = Color(0xFFE1E7EF);
  static const success = Color(0xFF39A900);
  static const warning = Color(0xFFF6A900);
  static const danger = Color(0xFFE53935);
  static const info = Color(0xFF1565C0);
}

abstract final class SimaTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: SimaColors.green,
      brightness: Brightness.light,
      primary: SimaColors.green,
      secondary: SimaColors.navy,
      surface: SimaColors.surface,
      error: SimaColors.danger,
    );

    const radius = BorderRadius.all(Radius.circular(13));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SimaColors.background,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: SimaColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: SimaColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: SimaColors.navy,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: SimaColors.navy,
          fontSize: 15,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: SimaColors.textMuted,
          fontSize: 13,
          height: 1.4,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SimaColors.navyDeep,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: SimaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: SimaColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: SimaColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: SimaColors.textSoft, fontSize: 14),
        labelStyle: TextStyle(
          color: SimaColors.navy,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: SimaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: SimaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: SimaColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: SimaColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: SimaColors.danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SimaColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SimaColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SimaColors.navy,
          minimumSize: const Size(48, 46),
          side: const BorderSide(color: SimaColors.border),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SimaColors.navy,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: SimaColors.green,
        unselectedLabelColor: SimaColors.textMuted,
        indicatorColor: SimaColors.green,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SimaColors.navy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SimaColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: SimaColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SimaColors.green,
        linearTrackColor: Color(0xFFE8EEF5),
      ),
    );
  }
}
