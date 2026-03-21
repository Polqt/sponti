import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/reviews/model/review.dart';
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

final myReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final result = await ref.read(reviewsRepositoryProvider).getMyReviews();

  return result.fold((failure) {
    throw StateError(failure.message);
  }, (reviews) => reviews);
});
