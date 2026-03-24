import 'package:flutter/material.dart';
import 'package:sponti/core/widgets/location_feedback_widgets.dart';
import 'package:sponti/features/locations/view/screens/location_feedback_page.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    return LocationFeedbackPage(
      locationId: locationId,
      locationName: locationName,
      initialMode: LocationFeedbackMode.reviews,
    );
  }
}
