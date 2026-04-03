import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/model/review_model.dart';
import 'package:sponti/features/reviews/repository/reviews_remote_data_source.dart';
import 'package:sponti/features/reviews/repository/reviews_repository.dart';

class ReviewsRepositoryImpl extends BaseRepository implements ReviewsRepository {
  const ReviewsRepositoryImpl(this._remote);

  final ReviewsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Review>>> getReviewsForLocation(String locationId) =>
      guard(() => _remote.getReviewsForLocation(locationId));

  @override
  Future<Either<Failure, Review?>> getMyReviewForLocation(String locationId) =>
      guard(() => _remote.getMyReviewForLocation(locationId));

  @override
  Future<Either<Failure, List<Review>>> getMyReviews() =>
      guard(_remote.getMyReviews);

  @override
  Future<Either<Failure, Review>> createReview(Review review) =>
      guard(() => _remote.createReview(ReviewModel.fromEntity(review)));

  @override
  Future<Either<Failure, Review>> updateReview(Review review) =>
      guard(() => _remote.updateReview(ReviewModel.fromEntity(review)));

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) =>
      guard(() => _remote.deleteReview(reviewId));
}
