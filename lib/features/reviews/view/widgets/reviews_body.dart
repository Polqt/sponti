import 'package:flutter/material.dart';
import 'package:sponti/features/reviews/view/widgets/review_form.dart';

class ReviewsBody extends StatelessWidget {
  const ReviewsBody({super.key, this.locationId});

  final String? locationId;

  @override
  Widget build(BuildContext context) {
    return ReviewForm(
      locationName: locationId == null ? 'Write a review' : 'Location review',
    );
  }
}
