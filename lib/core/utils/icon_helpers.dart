import 'dart:convert';
import 'package:flutter/services.dart';

/// Holds either SVG string or PNG bytes for resolved icons.
class ResolvedCategoryIcon {
  final Uint8List? bytes;
  final String? svg;

  const ResolvedCategoryIcon._({this.bytes, this.svg});

  factory ResolvedCategoryIcon.svg(String svg) =>
      ResolvedCategoryIcon._(svg: svg);
  factory ResolvedCategoryIcon.bytes(Uint8List bytes) =>
      ResolvedCategoryIcon._(bytes: bytes);
  static const empty = ResolvedCategoryIcon._();
}

final Map<String, Future<ResolvedCategoryIcon>> _iconCache =
    <String, Future<ResolvedCategoryIcon>>{};

Future<ResolvedCategoryIcon> resolveCategoryIcon(String assetPath) {
  return _iconCache.putIfAbsent(assetPath, () async {
    final svg = await rootBundle
        .loadString(assetPath, cache: false)
        // ignore: invalid_return_type_for_catch_error
        .catchError((_) => null);
    final match = RegExp(
      r'data:image\/png;base64,([^"]+)',
      caseSensitive: false,
    ).firstMatch(svg);
    final encoded = match?.group(1);
    if (encoded != null) {
      return ResolvedCategoryIcon.bytes(base64Decode(encoded));
    }
    return ResolvedCategoryIcon.svg(svg);
  });
}
