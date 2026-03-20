import 'package:flutter/material.dart';
import 'package:sponti/features/reviews/view/widgets/reviews_body.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key, this.locationId});

  final String? locationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: ReviewsBody(locationId: locationId),
    );
  }
}
