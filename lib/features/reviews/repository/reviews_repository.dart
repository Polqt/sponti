import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/reviews/model/review.dart';

abstract interface class ReviewsRepository {
  Future<Either<Failure, ReviewPage>> getReviewsForLocationPage(
    String locationId, {
    ReviewPageCursor? cursor,
    int limit = 30,
  });
  Future<Either<Failure, Review?>> getMyReviewForLocation(String locationId);
  Future<Either<Failure, List<Review>>> getMyReviews();
  Future<Either<Failure, Review>> createReview(Review review);
  Future<Either<Failure, Review>> updateReview(Review review);
  Future<Either<Failure, void>> deleteReview(String reviewId);
}
