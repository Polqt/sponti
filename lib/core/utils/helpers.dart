import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

abstract final class SpontiSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = isError
        ? SpontiColors.error
        : isSuccess
        ? SpontiColors.success
        : SpontiColors.dark;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, isSuccess: true);
  }

  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }
}

// URL Helper
abstract final class UrlHelper {
  // Open google maps directions
  static Future<void> openDirections(double lat, double lng) async {
    final uri = Uri.parse('https://maps.google.com?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Open URL in an external browser
  static Future<void> openeUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Open instagram profile
  static Future<void> openInstagram(String username) async {
    final appUri = Uri.parse('instagram://user?username=$username');
    final webUri = Uri.parse('https://instagram.com/$username');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

// Haptics
abstract final class HapticHelper {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
}

// Distance Calculation
abstract final class GeoHelper {
  // Haversine formula to calculate distance between two lat/lng points in kilometers
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}

// Extensions
extension StringHelpers on String {
  // Capitalzie first letter
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  // Title case
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');

  // Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension DateTimeHelpers on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final diff = now.difference(this).inDays;
    return diff >= 0 && diff < 7;
  }
}
