import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sponti/core/theme/app_colors.dart';

abstract final class SpontiTheme {
  /// Light theme only
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: SpontiColors.primary,
      onPrimary: SpontiColors.white,
      primaryContainer: Color(0xFFFFDDD0),
      onPrimaryContainer: SpontiColors.primaryDark,
      secondary: SpontiColors.secondary,
      onSecondary: SpontiColors.white,
      surface: SpontiColors.surface,
      onSurface: SpontiColors.textPrimary,
      onSurfaceVariant: SpontiColors.textSecondary,
      outline: SpontiColors.outline,
      error: SpontiColors.error,
      onError: SpontiColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SpontiColors.surface,

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: SpontiColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: SpontiColors.textPrimary),
        actionsIconTheme: IconThemeData(color: SpontiColors.textSecondary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: SpontiColors.textPrimary,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: SpontiColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: SpontiColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: SpontiColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: SpontiColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: SpontiColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: SpontiColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: SpontiColors.textMuted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textSecondary,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: SpontiColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SpontiColors.outline),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpontiColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: SpontiColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: SpontiColors.primary, width: 2),
        errorBorder: _inputBorder(color: SpontiColors.error),
        focusedErrorBorder: _inputBorder(color: SpontiColors.error, width: 2),
        prefixIconColor: SpontiColors.textMuted,
        suffixIconColor: SpontiColors.textMuted,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SpontiColors.primary,
          foregroundColor: SpontiColors.white,
          disabledBackgroundColor: SpontiColors.outline,
          disabledForegroundColor: SpontiColors.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SpontiColors.primary,
          side: const BorderSide(color: SpontiColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SpontiColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: SpontiColors.surfaceVariant,
        selectedColor: SpontiColors.primary,
        disabledColor: SpontiColors.surfaceVariant,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SpontiColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: SpontiColors.outline),
        ),
        side: const BorderSide(color: SpontiColors.outline),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SpontiColors.white,
        elevation: 0,
        selectedItemColor: SpontiColors.primary,
        unselectedItemColor: SpontiColors.textMuted,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: SpontiColors.outline,
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SpontiColors.dark,
        contentTextStyle: const TextStyle(
          color: SpontiColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: SpontiColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SpontiColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: SpontiColors.textSecondary,
          height: 1.5,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SpontiColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: SpontiColors.textSecondary,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SpontiColors.primary,
      ),
    );
  }

  static OutlineInputBorder _inputBorder({
    Color color = SpontiColors.outline,
    double width = 1,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}
