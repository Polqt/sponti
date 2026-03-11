import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_shimmer.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
  }) : _isCircle = false,
       _size = null;

  const AppNetworkImage.circle({
    super.key,
    required this.url,
    required double size,
    this.fallbackIcon = Icons.person_outline_rounded,
  }) : _isCircle = true,
       _size = size,
       height = size,
       width = size,
       fit = BoxFit.cover,
       borderRadius = null;

  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final bool _isCircle;
  final double? _size;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    Widget image = hasUrl
        ? CachedNetworkImage(
            imageUrl: url!,
            height: height,
            width: width ?? double.infinity,
            fit: fit,
            placeholder: (_, _) => _Placeholder(height: height, width: width),
            errorWidget: (_, _, _) =>
                _Fallback(height: height, width: width, icon: fallbackIcon),
          )
        : _Fallback(height: height, width: width, icon: fallbackIcon);

    if (_isCircle) {
      return ClipOval(
        child: SizedBox(width: _size, height: _size, child: image),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.height, this.width});
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) =>
      AppShimmer(height: height ?? 200, width: width, borderRadius: 0);
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.height, this.width, required this.icon});
  final double? height;
  final double? width;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width ?? double.infinity,
    color: SpontiColors.surfaceVariant,
    child: Center(child: Icon(icon, color: SpontiColors.textMuted, size: 32)),
  );
}
