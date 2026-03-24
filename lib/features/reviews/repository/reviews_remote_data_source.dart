import 'package:sponti/features/reviews/model/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ReviewsRemoteDataSource {
  Future<List<ReviewModel>> getReviewsForLocation(String locationId);
  Future<List<ReviewModel>> getMyReviews();
  Future<ReviewModel> createReview(ReviewModel review);
  Future<ReviewModel> updateReview(ReviewModel review);
  Future<void> deleteReview(String reviewId);
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  const ReviewsRemoteDataSourceImpl(this._client);

  // ignore: unused_field
  final SupabaseClient _client;

  @override
  Future<List<ReviewModel>> getReviewsForLocation(String locationId) async {
    throw UnimplementedError('Reviews remote data source is not wired yet.');
  }

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    throw UnimplementedError('Reviews remote data source is not wired yet.');
  }

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    throw UnimplementedError('Reviews remote data source is not wired yet.');
  }

  @override
  Future<ReviewModel> updateReview(ReviewModel review) async {
    throw UnimplementedError('Reviews remote data source is not wired yet.');
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    throw UnimplementedError('Reviews remote data source is not wired yet.');
  }
}
