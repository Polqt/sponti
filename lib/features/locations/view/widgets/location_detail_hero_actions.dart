import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';

class LocationDetailHeroActions extends StatelessWidget {
  const LocationDetailHeroActions({
    super.key,
    required this.locationId,
    required this.checkInCount,
    required this.onCheckInResult,
  });

  final String locationId;
  final int checkInCount;
  final void Function(bool didCheckIn, int previousCount) onCheckInResult;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FavoriteHeroActionButton(locationId: locationId),
        const SizedBox(width: 8),
        CheckInHeroActionButton(
          locationId: locationId,
          checkInCount: checkInCount,
          onCheckInResult: onCheckInResult,
        ),
      ],
    );
  }
}

class FavoriteHeroActionButton extends ConsumerWidget {
  const FavoriteHeroActionButton({
    super.key,
    required this.locationId,
  });

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteIdSetProvider);
    final isSaved = favoriteIds.contains(locationId);

    return _LocationHeroActionButton(
      icon: isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      semanticLabel: isSaved ? 'Remove from favorites' : 'Save to favorites',
      isActive: isSaved,
      activeColor: SpontiColors.error,
      onPressed: () => ref.read(favoriteIdsProvider.notifier).toggle(locationId),
    );
  }
}

class CheckInHeroActionButton extends ConsumerStatefulWidget {
  const CheckInHeroActionButton({
    super.key,
    required this.locationId,
    required this.checkInCount,
    required this.onCheckInResult,
  });

  final String locationId;
  final int checkInCount;
  final void Function(bool didCheckIn, int previousCount) onCheckInResult;

  @override
  ConsumerState<CheckInHeroActionButton> createState() =>
      _CheckInHeroActionButtonState();
}

class _CheckInHeroActionButtonState
    extends ConsumerState<CheckInHeroActionButton> {
  bool _isSubmitting = false;

  Future<void> _toggleCheckIn() async {
    if (_isSubmitting) return;

    final checkInAsync = ref.read(checkInProvider(widget.locationId));
    if (checkInAsync.isLoading) return;

    final currentState = checkInAsync.valueOrNull ?? const CheckInState();
    final notifier = ref.read(checkInProvider(widget.locationId).notifier);
    final wasCheckedIn = currentState.isCheckedIn;

    setState(() => _isSubmitting = true);

    final success = wasCheckedIn
        ? await notifier.deleteCheckIn()
        : await notifier.checkIn();

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      widget.onCheckInResult(!wasCheckedIn, widget.checkInCount);
      return;
    }

    final message =
        ref.read(checkInProvider(widget.locationId)).valueOrNull?.errorMessage;
    if (message == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkInAsync = ref.watch(checkInProvider(widget.locationId));
    final checkInState = checkInAsync.valueOrNull ?? const CheckInState();
    final isCheckedIn = checkInState.isCheckedIn;

    return _LocationHeroActionButton(
      icon: isCheckedIn
          ? Icons.check_circle_rounded
          : Icons.check_circle_outline_rounded,
      semanticLabel: isCheckedIn ? 'Remove check-in' : 'Check in',
      isActive: isCheckedIn,
      activeColor: SpontiColors.info,
      isBusy: _isSubmitting || checkInState.isLoading || checkInAsync.isLoading,
      onPressed: _toggleCheckIn,
    );
  }
}

class _LocationHeroActionButton extends StatelessWidget {
  const _LocationHeroActionButton({
    required this.icon,
    required this.semanticLabel,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
    this.isBusy = false,
  });

  final IconData icon;
  final String semanticLabel;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isActive ? activeColor : SpontiColors.textPrimary;
    final backgroundColor = isActive
        ? activeColor.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isBusy ? null : onPressed,
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: foregroundColor,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: foregroundColor,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
