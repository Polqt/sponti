import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/repository/checkins_repository.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';

void main() {
  group('MyCheckInsNotifier', () {
    test('loads first page on build', () async {
      final page1 = _buildPage(ids: ['a', 'b', 'c'], hasMore: false);
      final repo = _FakeCheckinsRepository(pages: [page1]);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(myCheckInsProvider.future);

      expect(result.map((c) => c.id), ['a', 'b', 'c']);
      expect(container.read(myCheckInsProvider.notifier).hasMore, isFalse);
    });

    test('fetchNextPage appends second page', () async {
      final cursor = CheckInPageCursor(
        createdAt: _epoch,
        id: 'cursor-1',
      );
      final page1 = _buildPage(ids: ['a', 'b'], hasMore: true, nextCursor: cursor);
      final page2 = _buildPage(ids: ['c', 'd'], hasMore: false);
      final repo = _FakeCheckinsRepository(pages: [page1, page2]);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myCheckInsProvider.future);
      final notifier = container.read(myCheckInsProvider.notifier);

      expect(notifier.hasMore, isTrue);
      await notifier.fetchNextPage();

      final all = container.read(myCheckInsProvider).valueOrNull!;
      expect(all.map((c) => c.id), ['a', 'b', 'c', 'd']);
      expect(notifier.hasMore, isFalse);
    });

    test('fetchNextPage is a no-op when hasMore is false', () async {
      final page = _buildPage(ids: ['a'], hasMore: false);
      final repo = _FakeCheckinsRepository(pages: [page]);
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myCheckInsProvider.future);
      final notifier = container.read(myCheckInsProvider.notifier);
      await notifier.fetchNextPage(); // should not trigger a second call

      expect(repo.pageCallCount, 1);
    });

    test('fetchNextPage is a no-op when a fetch is already in flight', () async {
      final cursor = CheckInPageCursor(createdAt: _epoch, id: 'c1');
      final page1 = _buildPage(ids: ['a'], hasMore: true, nextCursor: cursor);
      final page2 = _buildPage(ids: ['b'], hasMore: false);
      final repo = _FakeCheckinsRepository(
        pages: [page1, page2],
        delay: const Duration(milliseconds: 50),
      );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(myCheckInsProvider.future);
      final notifier = container.read(myCheckInsProvider.notifier);

      // Fire two concurrent fetches — second should be ignored
      final f1 = notifier.fetchNextPage();
      final f2 = notifier.fetchNextPage();
      await Future.wait([f1, f2]);

      // Only one extra page call should have been made
      expect(repo.pageCallCount, 2); // initial + one page fetch
    });

    test('throws StateError when repository returns a failure', () async {
      final repo = _FakeCheckinsRepository(
        failure: const ServerFailure('db error'),
      );
      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(myCheckInsProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });
}

// ── helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeCheckinsRepository repo) {
  return ProviderContainer(
    overrides: [
      checkinsRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

CheckInPage _buildPage({
  required List<String> ids,
  required bool hasMore,
  CheckInPageCursor? nextCursor,
}) {
  final items = ids
      .map(
        (id) => CheckIn(
          id: id,
          locationId: 'loc-1',
          userId: 'user-1',
          createdAt: _epoch,
        ),
      )
      .toList();
  return CheckInPage(items: items, hasMore: hasMore, nextCursor: nextCursor);
}

final _epoch = DateTime.utc(2026, 1, 1);

// ignore: avoid_implementing_value_types
class _FakeCheckinsRepository implements CheckinsRepository {
  _FakeCheckinsRepository({
    List<CheckInPage>? pages,
    this.failure,
    this.delay = Duration.zero,
  }) : _pages = pages ?? [];

  final List<CheckInPage> _pages;
  final Failure? failure;
  final Duration delay;
  int pageCallCount = 0;

  @override
  Future<Either<Failure, CheckInPage>> getMyCheckInsPage({
    CheckInPageCursor? cursor,
    int limit = 30,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failure != null) return Left(failure!);
    final page = _pages[pageCallCount.clamp(0, _pages.length - 1)];
    pageCallCount++;
    return Right(page);
  }

  @override
  Future<Either<Failure, List<CheckIn>>> getCheckInsForLocation(
    String locationId,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, CheckIn>> createCheckIn({
    required String locationId,
    required String userId,
    String? note,
    List<String> photos = const [],
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, CheckIn>> updateCheckIn({
    required String checkInId,
    String? note,
    List<String> photos = const [],
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteCheckIn(String checkInId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> hasUserCheckedIn(
    String locationId,
    String userId,
  ) => throw UnimplementedError();
}
