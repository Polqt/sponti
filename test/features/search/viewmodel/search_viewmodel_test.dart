import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/feature_flags.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/locations/model/coordinates.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/model/location_query.dart';
import 'package:sponti/features/locations/repository/location_repository.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/search/viewmodel/search_viewmodel.dart';

void main() {
  group('searchResultsProvider', () {
    test('uses legacy search when ranked search flag is disabled', () async {
      final repository = _FakeLocationRepository(
        legacyResults: [_buildLocation(id: 'legacy-1', name: 'Cafe Bobs')],
      );
      final container = ProviderContainer(
        overrides: [
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(
              useRankedSearch: false,
              useCursorPagination: false,
              useLocationMetrics: false,
            ),
          ),
          locationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'cafe';
      final results = await container.read(searchResultsProvider.future);

      expect(repository.legacySearchCalls, 1);
      expect(repository.rankedSearchCalls, 0);
      expect(results.single.id, 'legacy-1');
    });

    test('uses ranked search when the feature flag is enabled', () async {
      final repository = _FakeLocationRepository(
        rankedResults: [_buildLocation(id: 'ranked-1', name: 'Cafe Culture')],
      );
      final container = ProviderContainer(
        overrides: [
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(
              useRankedSearch: true,
              useCursorPagination: false,
              useLocationMetrics: false,
            ),
          ),
          locationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'cafe';
      final results = await container.read(searchResultsProvider.future);

      expect(repository.legacySearchCalls, 0);
      expect(repository.rankedSearchCalls, 1);
      expect(results.single.id, 'ranked-1');
    });

    test('falls back to legacy search when ranked search fails', () async {
      final repository = _FakeLocationRepository(
        legacyResults: [_buildLocation(id: 'legacy-fallback', name: 'Fallback Cafe')],
        rankedFailure: const ServerFailure('ranked search unavailable'),
      );
      final container = ProviderContainer(
        overrides: [
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(
              useRankedSearch: true,
              useCursorPagination: false,
              useLocationMetrics: false,
            ),
          ),
          locationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchQueryProvider.notifier).state = 'cafe';
      final results = await container.read(searchResultsProvider.future);

      expect(repository.rankedSearchCalls, 1);
      expect(repository.legacySearchCalls, 1);
      expect(results.single.id, 'legacy-fallback');
    });
  });
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({
    this.legacyResults = const <Location>[],
    this.rankedResults = const <Location>[],
    this.rankedFailure,
  });

  final List<Location> legacyResults;
  final List<Location> rankedResults;
  final Failure? rankedFailure;

  int legacySearchCalls = 0;
  int rankedSearchCalls = 0;

  @override
  Future<Either<Failure, List<Location>>> searchLocations(String query) async {
    legacySearchCalls += 1;
    return Right(legacyResults);
  }

  @override
  Future<Either<Failure, List<Location>>> searchLocationsRanked(
    RankedLocationSearchRequest request,
  ) async {
    rankedSearchCalls += 1;
    final failure = rankedFailure;
    if (failure != null) {
      return Left(failure);
    }
    return Right(rankedResults);
  }

  @override
  Future<Either<Failure, LocationPage>> getLocationsPage({
    LocationPageCursor? cursor,
    int limit = 30,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Location>>> getAllLocations({
    int page = 0,
    int pageSize = 1000,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Location>> getLocationById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Location>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Location>>> filterByCategory(
    LocationCategory category,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Location>>> fetchByCategories(
    List<String> categories,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Location>> createLocation(Location location) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Location>> updateLocation(Location location) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> deleteLocation(String id) {
    throw UnimplementedError();
  }
}

Location _buildLocation({
  required String id,
  required String name,
}) {
  return Location(
    id: id,
    name: name,
    description: 'A test spot',
    category: LocationCategory.coffee,
    coordinates: const Coordinates(latitude: 10.67, longitude: 122.95),
    address: 'Lacson Street, Bacolod City',
    priceRange: PriceRange.budget,
    photoUrls: const <String>[],
    createdAt: DateTime.utc(2026, 4, 3),
  );
}
