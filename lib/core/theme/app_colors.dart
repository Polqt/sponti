import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Color Pallete -> Franz will change
abstract final class SpontiColors {
  // Brand
  static const Color primary = Color(0xFFE8612C);
  static const Color primaryLight = Color(0xFFF28A60);
  static const Color primaryDark = Color(0xFFC04A1C);
  static const Color secondary = Color(0xFF2C8C8E);
  static const Color secondaryLight = Color(0xFF4FBFC2);
  static const Color accent = Color(0xFFFFB830);

  // Surface
  static const Color surface = Color(0xFFFAF9F7);
  static const Color surfaceVariant = Color(0xFFF0EDE8);
  static const Color outline = Color(0xFFDDD9D3);
  static const Color shadow = Color(0xFF000000);
  static const Color dark = Color(0xFF1A1714);
  static const Color white = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1714);
  static const Color textSecondary = Color(0xFF6B6560);
  static const Color textMuted = Color(0xFF9E9A95);

  // Category semantic
  static const Color categoryFood = Color(0xFFE8612C);
  static const Color categoryCoffee = Color(0xFF7B4F2E);
  static const Color categoryNature = Color(0xFF3A7D44);
  static const Color categoryNightlife = Color(0xFF4A3B8C);
  static const Color categoryArts = Color(0xFFD4458C);
  static const Color categoryActivities = Color(0xFF2C8C8E);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);
}
