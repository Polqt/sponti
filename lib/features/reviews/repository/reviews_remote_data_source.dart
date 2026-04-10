import 'package:sponti/config/config.dart';
import 'package:sponti/core/errors/exceptions.dart' as app_exceptions;
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/model/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ReviewsRemoteDataSource {
  Future<ReviewPage> getReviewsForLocationPage(
    String locationId, {
    ReviewPageCursor? cursor,
    int limit = 30,
  });
  Future<ReviewModel?> getMyReviewForLocation(String locationId);
  Future<List<ReviewModel>> getMyReviews();
  Future<ReviewModel> createReview(ReviewModel review);
  Future<ReviewModel> updateReview(ReviewModel review);
  Future<void> deleteReview(String reviewId);
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  const ReviewsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _selectColumns = '''
    id, location_id, user_id, rating, comment, photos, created_at
  ''';

  @override
  Future<ReviewPage> getReviewsForLocationPage(
    String locationId, {
    ReviewPageCursor? cursor,
    int limit = 30,
  }) async {
    try {
      final effectiveLimit = limit.clamp(1, 100).toInt();
      dynamic query = _client
          .from(SupabaseTables.reviews)
          .select(_selectColumns)
          .eq('location_id', locationId)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(effectiveLimit + 1);

      if (cursor != null) {
        query = query.or(_buildCursorFilter(cursor));
      }

      final response = await query;
      final rows = (response as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
      final hasMore = rows.length > effectiveLimit;
      final pageRows = hasMore ? rows.take(effectiveLimit).toList() : rows;
      final items = pageRows
          .map((row) => ReviewModel.fromJson(row))
          .toList(growable: false);
      final nextCursor = hasMore && pageRows.isNotEmpty
          ? ReviewPageCursor(
              createdAt: DateTime.parse(pageRows.last['created_at'] as String)
                  .toUtc(),
              id: pageRows.last['id'] as String,
            )
          : null;

      return ReviewPage(items: items, hasMore: hasMore, nextCursor: nextCursor);
    } on PostgrestException catch (e) {
      throw app_exceptions.ServerException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<ReviewModel?> getMyReviewForLocation(String locationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const app_exceptions.AuthException(
          'You must be signed in to view your review.',
        );
      }

      final response = await _client
          .from(SupabaseTables.reviews)
          .select(_selectColumns)
          .eq('location_id', locationId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ReviewModel.fromJson(response);
    } on app_exceptions.AuthException {
      rethrow;
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
          .select(_selectColumns)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .order('id', ascending: false);

      return (response as List<dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on app_exceptions.AuthException {
      rethrow;
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

  String _buildCursorFilter(ReviewPageCursor cursor) {
    final createdAt = cursor.createdAt.toUtc().toIso8601String();
    return 'created_at.lt.$createdAt,and(created_at.eq.$createdAt,id.lt.${cursor.id})';
  }
}
