import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

enum AppButtonSize {
  small(height: 38, fontSize: 13, iconSize: 15, radius: 10),
  medium(height: 50, fontSize: 15, iconSize: 18, radius: 12),
  large(height: 58, fontSize: 17, iconSize: 20, radius: 14);

  const AppButtonSize({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.radius,
  });

  final double height;
  final double fontSize;
  final double iconSize;
  final double radius;

  EdgeInsets get padding => switch (this) {
    AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 16),
    AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24),
    AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 32),
  };
}

/// A unified button widget covering every variant in the app.
///
/// ```dart
/// // Primary (default)
/// AppButton(label: 'Get Directions', onPressed: () {})
///
/// // With icon
/// AppButton(label: 'Save', prefixIcon: Icons.bookmark, onPressed: () {})
///
/// // Loading
/// AppButton(label: 'Saving...', isLoading: true, onPressed: null)
///
/// // Named variants
/// AppButton.outline(label: 'Share', onPressed: () {})
/// AppButton.ghost(label: 'Skip', onPressed: () {})
/// AppButton.destructive(label: 'Delete', onPressed: () {})
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final config = _resolveConfig(variant);

    final content = _ButtonContent(
      label: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isLoading: isLoading,
      foreground: config.foreground,
      size: size,
    );

    final button = _isOutlined(variant)
        ? OutlinedButton(
            onPressed: isDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: config.foreground,
              backgroundColor: config.background,
              side: BorderSide(
                color: variant == AppButtonVariant.ghost
                    ? Colors.transparent
                    : config.foreground,
                width: 1.5,
              ),
              minimumSize: Size(0, size.height),
              padding: size.padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.radius),
              ),
            ),
            child: content,
          )
        : ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled
                  ? SpontiColors.outline
                  : config.background,
              foregroundColor: config.foreground,
              disabledForegroundColor: SpontiColors.textMuted,
              elevation: 0,
              minimumSize: Size(0, size.height),
              padding: size.padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.radius),
              ),
            ),
            child: content,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final canExpand = constraints.maxWidth.isFinite;
        return isFullWidth && canExpand
            ? SizedBox(width: double.infinity, child: button)
            : button;
      },
    );
  }

  bool _isOutlined(AppButtonVariant v) =>
      v == AppButtonVariant.outline || v == AppButtonVariant.ghost;

  ({Color background, Color foreground}) _resolveConfig(
    AppButtonVariant variant,
  ) => switch (variant) {
    AppButtonVariant.primary => (
      background: SpontiColors.primary,
      foreground: SpontiColors.white,
    ),
    AppButtonVariant.secondary => (
      background: SpontiColors.secondary,
      foreground: SpontiColors.white,
    ),
    AppButtonVariant.outline || AppButtonVariant.ghost => (
      background: Colors.transparent,
      foreground: SpontiColors.primary,
    ),
    AppButtonVariant.destructive => (
      background: SpontiColors.error,
      foreground: SpontiColors.white,
    ),
  };
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.foreground,
    required this.isLoading,
    required this.size,
    this.prefixIcon,
    this.suffixIcon,
  });

  final String label;
  final Color foreground;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: size.iconSize,
        width: size.iconSize,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: size.iconSize),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: size.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: size.iconSize),
        ],
      ],
    );
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.isSaved, this.onTap});
  final bool isSaved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 16,
        color: isSaved ? SpontiColors.primary : SpontiColors.textSecondary,
      ),
    ),
  );
}
