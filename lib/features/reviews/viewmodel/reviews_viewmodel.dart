import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/config.dart';
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

const _reviewsPageSize = 20;

class ReviewsByLocationNotifier
    extends FamilyAsyncNotifier<List<Review>, String> {
  ReviewPageCursor? _nextCursor;
  bool _hasMore = false;
  bool _isFetchingNextPage = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<Review>> build(String locationId) async {
    _nextCursor = null;
    _hasMore = false;

    final repository = ref.read(reviewsRepositoryProvider);
    final result = await repository.getReviewsForLocationPage(
      locationId,
      limit: _reviewsPageSize,
    );
    return result.fold(
      (failure) => throw StateError(failure.message),
      (page) {
        _hasMore = page.hasMore;
        _nextCursor = page.nextCursor;
        return page.items;
      },
    );
  }

  /// Returns an error message on failure, null on success.
  Future<String?> fetchNextPage() async {
    if (!_hasMore || _nextCursor == null || _isFetchingNextPage) return null;
    final current = state.valueOrNull;
    if (current == null) return null;

    _isFetchingNextPage = true;
    try {
      final repository = ref.read(reviewsRepositoryProvider);
      final result = await repository.getReviewsForLocationPage(
        arg,
        cursor: _nextCursor,
        limit: _reviewsPageSize,
      );
      return result.fold(
        (f) => f.message,
        (page) {
          _hasMore = page.hasMore;
          _nextCursor = page.nextCursor;
          state = AsyncData([...current, ...page.items]);
          return null;
        },
      );
    } finally {
      _isFetchingNextPage = false;
    }
  }
}

final reviewsByLocationProvider = AsyncNotifierProviderFamily<
    ReviewsByLocationNotifier, List<Review>, String>(
  ReviewsByLocationNotifier.new,
);

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
