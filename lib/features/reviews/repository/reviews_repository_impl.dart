import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/model/review_model.dart';
import 'package:sponti/features/reviews/repository/reviews_remote_data_source.dart';
import 'package:sponti/features/reviews/repository/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  const ReviewsRepositoryImpl(this._remote);

  final ReviewsRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getReviewsForLocation(String locationId) =>
      _guard(() => _remote.getReviewsForLocation(locationId));

  @override
  Future<Either<Failure, List<Review>>> getMyReviews() =>
      _guard(_remote.getMyReviews);

  @override
  Future<Either<Failure, Review>> createReview(Review review) =>
      _guard(() => _remote.createReview(ReviewModel.fromEntity(review)));

  @override
  Future<Either<Failure, Review>> updateReview(Review review) =>
      _guard(() => _remote.updateReview(ReviewModel.fromEntity(review)));

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) =>
      _guard(() => _remote.deleteReview(reviewId));
}
