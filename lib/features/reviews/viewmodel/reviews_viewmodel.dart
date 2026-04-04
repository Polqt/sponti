import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/feature_flags.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/model/review_model.dart';
import 'package:sponti/features/reviews/repository/reviews_remote_data_source.dart';
import 'package:sponti/features/reviews/repository/reviews_repository.dart';
import 'package:sponti/features/reviews/repository/reviews_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((ref) {
  return ReviewsRemoteDataSourceImpl(Supabase.instance.client);
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepositoryImpl(ref.read(reviewsRemoteDataSourceProvider));
});

final reviewsByLocationProvider =
    FutureProvider.family<List<Review>, String>((ref, locationId) async {
      final repository = ref.read(reviewsRepositoryProvider);
      final useCursor = ref.watch(featureFlagsProvider).useCursorPagination;

      if (!useCursor) {
        final firstPageResult = await repository.getReviewsForLocationPage(
          locationId,
          limit: 100,
        );
        return firstPageResult.fold((failure) {
          throw StateError(failure.message);
        }, (page) => page.items);
      }

      final items = <Review>[];
      ReviewPageCursor? cursor;

      while (true) {
        final result = await repository.getReviewsForLocationPage(
          locationId,
          cursor: cursor,
          limit: 30,
        );
        final page = result.fold(
          (failure) => throw StateError(failure.message),
          (p) => p,
        );
        items.addAll(page.items);
        if (!page.hasMore || page.nextCursor == null) {
          break;
        }
        cursor = page.nextCursor;
      }

      return List.unmodifiable(items);
    });

final reviewsStreamProvider =
    StreamProvider.family<List<Review>, String>((ref, locationId) {
      final client = Supabase.instance.client;

      return client
          .from(SupabaseTables.reviews)
          .stream(primaryKey: const ['id'])
          .eq('location_id', locationId)
          .limit(20)
          .map((rows) {
            final reviews = rows
                .map(
                  (row) =>
                      ReviewModel.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList(growable: true)
              ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

            return reviews;
          });
    });

final myReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final result = await ref.read(reviewsRepositoryProvider).getMyReviews();

  return result.fold((failure) {
    throw StateError(failure.message);
  }, (reviews) => reviews);
});

final myReviewForLocationProvider =
    FutureProvider.family<Review?, String>((ref, locationId) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final result = await ref
          .read(reviewsRepositoryProvider)
          .getMyReviewForLocation(locationId);

      return result.fold((failure) {
        throw StateError(failure.message);
      }, (review) => review);
    });
