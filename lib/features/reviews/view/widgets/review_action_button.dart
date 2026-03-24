import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/widgets/app_button.dart';

class ReviewActionButton extends StatelessWidget {
  const ReviewActionButton({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    return AppButton.outline(
      label: 'Review',
      size: AppButtonSize.medium,
      prefixIcon: Icons.rate_review_outlined,
      onPressed: () => context.push(
        RouteName.reviewsPath(
          locationId: locationId,
          locationName: locationName,
        ),
      ),
    );
  }
}
