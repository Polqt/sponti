import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return ReviewsRepositoryImpl(ref.watch(reviewsRemoteDataSourceProvider));
});

final reviewsByLocationProvider =
    FutureProvider.family<List<Review>, String>((ref, locationId) async {
      final result = await ref
          .read(reviewsRepositoryProvider)
          .getReviewsForLocation(locationId);

      return result.fold((failure) {
        throw StateError(failure.message);
      }, (reviews) => reviews);
    });

final reviewsStreamProvider =
    StreamProvider.family<List<Review>, String>((ref, locationId) {
      final client = Supabase.instance.client;

      return client
          .from(SupabaseTables.reviews)
          .stream(primaryKey: const ['id'])
          .eq('location_id', locationId)
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
          .getReviewsForLocation(locationId);

      return result.fold((failure) {
        throw StateError(failure.message);
      }, (reviews) {
        for (final review in reviews) {
          if (review.userId == userId) return review;
        }
        return null;
      });
    });
