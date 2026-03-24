import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';

class CheckInActionButton extends StatelessWidget {
  const CheckInActionButton({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.isCheckedIn,
    required this.checkInCount,
    required this.onCheckInResult,
  });

  final String locationId;
  final String locationName;
  final bool isCheckedIn;
  final int checkInCount;
  final void Function(bool?, int) onCheckInResult;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          RouteName.checkInPath(
            locationId: locationId,
            locationName: locationName,
          ),
        );
        onCheckInResult(result, checkInCount);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 50,
        decoration: BoxDecoration(
          color: isCheckedIn
              ? SpontiColors.secondary.withValues(alpha: 0.1)
              : SpontiColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCheckedIn
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: isCheckedIn ? SpontiColors.secondary : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isCheckedIn ? 'Visited' : 'Check in',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isCheckedIn ? SpontiColors.secondary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
