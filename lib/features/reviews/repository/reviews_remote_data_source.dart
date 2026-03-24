import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/core/errors/exceptions.dart' as app_exceptions;
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
    try {
      final response = await _client
          .from(SupabaseTables.reviews)
          .select()
          .eq('location_id', locationId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const app_exceptions.AuthException(
          'You must be signed in to view your reviews.',
        );
      }

      final response = await _client
          .from(SupabaseTables.reviews)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    try {
      final response = await _client
          .from(SupabaseTables.reviews)
          .upsert(
            review.toUpsertJson(),
            onConflict: 'location_id,user_id',
          )
          .select()
          .single();

      return ReviewModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<ReviewModel> updateReview(ReviewModel review) async {
    try {
      final response = await _client
          .from(SupabaseTables.reviews)
          .update(review.toUpdateJson())
          .eq('id', review.id)
          .select()
          .single();

      return ReviewModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await _client.from(SupabaseTables.reviews).delete().eq('id', reviewId);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(e.toString());
    }
  }
}
