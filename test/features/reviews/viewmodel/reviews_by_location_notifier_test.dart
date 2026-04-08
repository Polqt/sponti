import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/reviews/model/review.dart';
import 'package:sponti/features/reviews/repository/reviews_repository.dart';
import 'package:sponti/features/reviews/viewmodel/reviews_viewmodel.dart';

void main() {
  group('ReviewsByLocationNotifier', () {
    test('loads first page on build', () async {
      final page = _buildPage(ids: ['r1', 'r2'], hasMore: false);
      final repo = _FakeReviewsRepository(pages: [page]);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result =
          await container.read(reviewsByLocationProvider('loc-1').future);

      expect(result.map((r) => r.id), ['r1', 'r2']);
      expect(
        container.read(reviewsByLocationProvider('loc-1').notifier).hasMore,
        isFalse,
      );
    });

    test('fetchNextPage appends second page', () async {
      final cursor = ReviewPageCursor(
        createdAt: DateTime.utc(2026, 1, 1),
        id: 'r2',
      );
      final page1 = _buildPage(ids: ['r1', 'r2'], hasMore: true, nextCursor: cursor);
      final page2 = _buildPage(ids: ['r3', 'r4'], hasMore: false);
      final repo = _FakeReviewsRepository(pages: [page1, page2]);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(reviewsByLocationProvider('loc-1').future);
      final notifier =
          container.read(reviewsByLocationProvider('loc-1').notifier);

      expect(notifier.hasMore, isTrue);
      await notifier.fetchNextPage();

      final all =
          container.read(reviewsByLocationProvider('loc-1')).valueOrNull!;
      expect(all.map((r) => r.id), ['r1', 'r2', 'r3', 'r4']);
      expect(notifier.hasMore, isFalse);
    });

    test('fetchNextPage is a no-op when hasMore is false', () async {
      final page = _buildPage(ids: ['r1'], hasMore: false);
      final repo = _FakeReviewsRepository(pages: [page]);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(reviewsByLocationProvider('loc-1').future);
      final notifier =
          container.read(reviewsByLocationProvider('loc-1').notifier);
      await notifier.fetchNextPage();

      expect(repo.pageCallCount, 1);
    });

    test('fetchNextPage deduplicates concurrent calls', () async {
      final cursor = ReviewPageCursor(
        createdAt: DateTime.utc(2026, 1, 1),
        id: 'r1',
      );
      final page1 = _buildPage(ids: ['r1'], hasMore: true, nextCursor: cursor);
      final page2 = _buildPage(ids: ['r2'], hasMore: false);
      final repo = _FakeReviewsRepository(
        pages: [page1, page2],
        delay: const Duration(milliseconds: 50),
      );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(reviewsByLocationProvider('loc-1').future);
      final notifier =
          container.read(reviewsByLocationProvider('loc-1').notifier);

      final f1 = notifier.fetchNextPage();
      final f2 = notifier.fetchNextPage();
      await Future.wait([f1, f2]);

      expect(repo.pageCallCount, 2); // initial build + one page fetch
    });

    test('throws StateError when repository returns a failure', () async {
      final repo = _FakeReviewsRepository(
        failure: const ServerFailure('network error'),
      );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(reviewsByLocationProvider('loc-1').future),
        throwsA(isA<StateError>()),
      );
    });
  });
}

// ── helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeReviewsRepository repo) {
  return ProviderContainer(
    overrides: [reviewsRepositoryProvider.overrideWithValue(repo)],
  );
}

ReviewPage _buildPage({
  required List<String> ids,
  required bool hasMore,
  ReviewPageCursor? nextCursor,
}) {
  final items = ids
      .map(
        (id) => Review(
          id: id,
          locationId: 'loc-1',
          userId: 'user-1',
          rating: 5,
          comment: 'great',
          photos: const [],
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      )
      .toList();
  return ReviewPage(items: items, hasMore: hasMore, nextCursor: nextCursor);
}

class _FakeReviewsRepository implements ReviewsRepository {
  _FakeReviewsRepository({
    List<ReviewPage>? pages,
    this.failure,
    this.delay = Duration.zero,
  }) : _pages = pages ?? [];

  final List<ReviewPage> _pages;
  final Failure? failure;
  final Duration delay;
  int pageCallCount = 0;

  @override
  Future<Either<Failure, ReviewPage>> getReviewsForLocationPage(
    String locationId, {
    ReviewPageCursor? cursor,
    int limit = 30,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failure != null) return Left(failure!);
    final page = _pages[pageCallCount.clamp(0, _pages.length - 1)];
    pageCallCount++;
    return Right(page);
  }

  @override
  Future<Either<Failure, Review?>> getMyReviewForLocation(String locationId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Review>>> getMyReviews() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Review>> createReview(Review review) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Review>> updateReview(Review review) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) =>
      throw UnimplementedError();
}
