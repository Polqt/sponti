import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class LocationDetailInset extends StatelessWidget {
  const LocationDetailInset({
    super.key,
    required this.top,
    required this.child,
    this.horizontal = 20,
  });

  final double top;
  final double horizontal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 0),
      child: child,
    );
  }
}

class LocationDetailSection extends StatelessWidget {
  const LocationDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.top = 20,
    this.horizontal = 20,
    this.spacing = 10,
  });

  final String title;
  final Widget child;
  final double top;
  final double horizontal;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LocationDetailInset(
      top: top,
      horizontal: horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationDetailSectionTitle(title),
          SizedBox(height: spacing),
          child,
        ],
      ),
    );
  }
}

class LocationDetailSectionTitle extends StatelessWidget {
  const LocationDetailSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SpontiColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class LocationDetailDivider extends StatelessWidget {
  const LocationDetailDivider({super.key, required this.top});

  final double top;

  @override
  Widget build(BuildContext context) {
    return LocationDetailInset(
      top: top,
      child: const Divider(color: SpontiColors.outline, height: 1),
    );
  }
}
