import 'package:flutter/material.dart';
import 'package:sponti/features/reviews/model/review.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(review.comment.isEmpty ? 'No comment yet' : review.comment),
        subtitle: Text('Rating: ${review.rating}/5'),
      ),
    );
  }
}
