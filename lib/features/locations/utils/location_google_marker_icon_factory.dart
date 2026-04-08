import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:sponti/core/utils/icon_helpers.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/utils/location_category_assets.dart';
import 'package:sponti/features/locations/utils/location_marker_style.dart';
import 'package:sponti/features/locations/utils/location_ranking.dart';

class LocationGoogleMarkerIconFactory {
  static final Map<String, Future<gmaps.BitmapDescriptor>> _cache =
      <String, Future<gmaps.BitmapDescriptor>>{};

  static String cacheKeyFor({
    required LocationCategory category,
    required PriceRange priceRange,
    required bool isSelected,
    required bool isTrending,
    required LocationRanking? ranking,
    required LocationRanking? activeRankingFilter,
    required PriceRange? activePriceFilter,
  }) {
    final rankingIndicator = resolveLocationMarkerRanking(
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
    );
    final accent = resolveLocationMarkerAccent(
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
      activePriceFilter: activePriceFilter,
    );

    return [
      category.name,
      priceRange.name,
      if (rankingIndicator != null) rankingIndicator.name else 'none',
      if (activePriceFilter != null) activePriceFilter.name else 'none',
      if (accent != null) accent.toARGB32().toRadixString(16) else 'none',
      if (isSelected) 'selected' else 'idle',
      if (isTrending) 'trending' else 'normal',
    ].join('|');
  }

  static Future<gmaps.BitmapDescriptor> resolve({
    required LocationCategory category,
    required PriceRange priceRange,
    required bool isSelected,
    required bool isTrending,
    required LocationRanking? ranking,
    required LocationRanking? activeRankingFilter,
    required PriceRange? activePriceFilter,
  }) {
    final rankingIndicator = resolveLocationMarkerRanking(
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
    );
    final accent = resolveLocationMarkerAccent(
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
      activePriceFilter: activePriceFilter,
    );
    final cacheKey = cacheKeyFor(
      category: category,
      priceRange: priceRange,
      isSelected: isSelected,
      isTrending: isTrending,
      ranking: ranking,
      activeRankingFilter: activeRankingFilter,
      activePriceFilter: activePriceFilter,
    );

    return _cache.putIfAbsent(
      cacheKey,
      () => _build(
        category: category,
        priceRange: priceRange,
        isSelected: isSelected,
        isTrending: isTrending,
        rankingIndicator: rankingIndicator,
        accent: accent,
        showPriceBadge: activePriceFilter != null,
      ),
    );
  }

  static Future<gmaps.BitmapDescriptor> resolveCurrentLocationPin() {
    return _cache.putIfAbsent('current-location-person-pin', () async {
      const pixelRatio = 3.0;
      const logicalSize = 56.0;
      final imageSize = (logicalSize * pixelRatio).round();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio, pixelRatio);

      final center = const Offset(logicalSize / 2, logicalSize / 2);
      const pinColor = Color(0xFF3B82F6);
      const white = Colors.white;

      final pinPath = Path()
        ..moveTo(center.dx, logicalSize - 6)
        ..cubicTo(
          center.dx + 15,
          logicalSize - 24,
          logicalSize - 8,
          logicalSize * 0.54,
          logicalSize - 8,
          logicalSize * 0.34,
        )
        ..arcToPoint(
          Offset(8, logicalSize * 0.34),
          radius: const Radius.circular(20),
          clockwise: false,
        )
        ..cubicTo(
          8,
          logicalSize * 0.54,
          center.dx - 15,
          logicalSize - 24,
          center.dx,
          logicalSize - 6,
        )
        ..close();

      canvas.drawPath(
        pinPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
      );
      canvas.drawPath(pinPath, Paint()..color = pinColor);

      canvas.drawCircle(center.translate(0, -8), 11, Paint()..color = white);

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.person_rounded.codePoint),
          style: const TextStyle(
            fontFamily: 'MaterialIcons',
            fontSize: 12,
            color: pinColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          center.dx - (iconPainter.width / 2),
          center.dy - 14 - (iconPainter.height / 2),
        ),
      );

      final image = await recorder.endRecording().toImage(imageSize, imageSize);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueAzure,
        );
      }

      return gmaps.BitmapDescriptor.bytes(
        Uint8List.fromList(bytes),
        imagePixelRatio: pixelRatio,
        width: logicalSize,
        height: logicalSize,
      );
    });
  }

  static Future<gmaps.BitmapDescriptor> _build({
    required LocationCategory category,
    required PriceRange priceRange,
    required bool isSelected,
    required bool isTrending,
    required LocationRanking? rankingIndicator,
    required Color? accent,
    required bool showPriceBadge,
  }) async {
    const pixelRatio = 3.0;
    final logicalSize = isSelected ? 52.0 : 46.0;
    final imageSize = (logicalSize * pixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(pixelRatio, pixelRatio);
    final center = Offset(logicalSize / 2, logicalSize / 2);
    final radius = logicalSize * 0.34;
    final accentColor = accent ?? const Color(0xFFD9D2CA);

    canvas.drawCircle(
      center.translate(0, 4),
      radius * 0.94,
      Paint()
        ..color = Colors.black.withValues(alpha: isSelected ? 0.18 : 0.12)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
    );

    // Trending: outer glow ring in orange, drawn before the white fill.
    if (isTrending) {
      canvas.drawCircle(
        center,
        radius + 3.5,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.28)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        center,
        radius + 2.2,
        Paint()
          ..color = const Color(0xFFFF6B35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(center, radius, [
          Colors.white,
          const Color(0xFFF8F4EE),
        ]),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accentColor.withValues(alpha: accent == null ? 0.16 : 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.8 : 2.0,
    );

    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..color = accentColor.withValues(alpha: accent == null ? 0.05 : 0.1),
    );

    await _paintCategoryIcon(
      canvas: canvas,
      bounds: Rect.fromCenter(
        center: center,
        width: isSelected ? 22 : 20,
        height: isSelected ? 22 : 20,
      ),
      category: category,
    );

    if (rankingIndicator != null) {
      final indicatorCenter = Offset(
        center.dx + (radius * 0.78),
        center.dy - (radius * 0.78),
      );
      canvas.drawCircle(indicatorCenter, 5.8, Paint()..color = Colors.white);
      canvas.drawCircle(
        indicatorCenter,
        4.2,
        Paint()..color = rankingIndicator.indicatorColor,
      );
    }

    if (showPriceBadge) {
      final badgeRect = Rect.fromCenter(
        center: Offset(
          center.dx - (radius * 0.88),
          center.dy + (radius * 0.88),
        ),
        width: 18,
        height: 12,
      );
      final badgeRRect = RRect.fromRectAndRadius(
        badgeRect,
        const Radius.circular(999),
      );
      final badgeColor = priceRange.accentColor;
      canvas.drawRRect(badgeRRect, Paint()..color = badgeColor);
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );

      final pricePainter = TextPainter(
        text: TextSpan(
          text: priceRange.symbol,
          style: const TextStyle(
            fontSize: 7.2,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: badgeRect.width);
      pricePainter.paint(
        canvas,
        Offset(
          badgeRect.center.dx - (pricePainter.width / 2),
          badgeRect.center.dy - (pricePainter.height / 2),
        ),
      );
    }

    final image = await recorder.endRecording().toImage(imageSize, imageSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) {
      return gmaps.BitmapDescriptor.defaultMarker;
    }

    return gmaps.BitmapDescriptor.bytes(
      Uint8List.fromList(bytes),
      imagePixelRatio: pixelRatio,
      width: logicalSize,
      height: logicalSize,
    );
  }

  static Future<void> _paintCategoryIcon({
    required Canvas canvas,
    required Rect bounds,
    required LocationCategory category,
  }) async {
    final resolved = await resolveCategoryIcon(category.assetPath);

    final bytes = resolved.bytes;
    if (bytes != null) {
      await _paintRasterIcon(canvas: canvas, bounds: bounds, bytes: bytes);
      return;
    }

    final rawSvg = resolved.svg;
    if (rawSvg != null) {
      await _paintSvgIcon(canvas: canvas, bounds: bounds, rawSvg: rawSvg);
      return;
    }

    _paintFallbackIcon(canvas: canvas, bounds: bounds, category: category);
  }

  static Future<void> _paintRasterIcon({
    required Canvas canvas,
    required Rect bounds,
    required Uint8List bytes,
  }) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: (bounds.width * 3).round(),
      targetHeight: (bounds.height * 3).round(),
    );

    try {
      final frame = await codec.getNextFrame();
      try {
        canvas.drawImageRect(
          frame.image,
          Rect.fromLTWH(
            0,
            0,
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ),
          bounds,
          Paint(),
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static Future<void> _paintSvgIcon({
    required Canvas canvas,
    required Rect bounds,
    required String rawSvg,
  }) async {
    final pictureInfo = await svg.vg.loadPicture(
      svg.SvgStringLoader(rawSvg),
      null,
    );

    try {
      final pictureSize = pictureInfo.size;
      if (pictureSize.isEmpty) return;

      final scale = _containScale(
        sourceWidth: pictureSize.width,
        sourceHeight: pictureSize.height,
        targetWidth: bounds.width,
        targetHeight: bounds.height,
      );
      final drawWidth = pictureSize.width * scale;
      final drawHeight = pictureSize.height * scale;
      final dx = bounds.left + ((bounds.width - drawWidth) / 2);
      final dy = bounds.top + ((bounds.height - drawHeight) / 2);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.scale(scale, scale);
      canvas.drawPicture(pictureInfo.picture);
      canvas.restore();
    } finally {
      pictureInfo.picture.dispose();
    }
  }

  static void _paintFallbackIcon({
    required Canvas canvas,
    required Rect bounds,
    required LocationCategory category,
  }) {
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(category.icon.codePoint),
        style: TextStyle(
          fontFamily: category.icon.fontFamily,
          package: category.icon.fontPackage,
          fontSize: math.min(bounds.width, bounds.height),
          color: const Color(0xFF2A2521),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        bounds.center.dx - (iconPainter.width / 2),
        bounds.center.dy - (iconPainter.height / 2),
      ),
    );
  }

  static double _containScale({
    required double sourceWidth,
    required double sourceHeight,
    required double targetWidth,
    required double targetHeight,
  }) {
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      return 1.0;
    }

    return math.min(targetWidth / sourceWidth, targetHeight / sourceHeight);
  }
}
