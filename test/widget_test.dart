import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/theme/app_theme.dart';
import 'package:sponti/features/favorites/view/screens/favorites_screen.dart';
import 'package:sponti/features/favorites/viewmodel/favorites_viewmodel.dart';
import 'package:sponti/features/location_comparison/viewmodel/location_comparison_viewmodel.dart';
import 'package:sponti/features/locations/model/coordinates.dart';
import 'package:sponti/features/locations/model/location.dart';

void main() {
  // Overrides to prevent Hive and Supabase from initializing in widget tests.
  final comparisonOverrides = [
    pinnedComparisonIdsProvider.overrideWith(_StubComparisonViewModel.new),
    pinnedComparisonIdSetProvider.overrideWithValue(const <String>{}),
  ];

  testWidgets('shows empty state when there are no saved places', (
    WidgetTester tester,
  ) async {
    testFavoriteIds = const <String>[];
    testLocations = const <Location>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteIdsProvider.overrideWith(TestFavoritesViewModel.new),
          favoriteLocationsProvider.overrideWith(
            (ref) async {
              final ids = await ref.watch(favoriteIdsProvider.future);
              return testLocations
                  .where((location) => ids.contains(location.id))
                  .toList(growable: false);
            },
          ),
          ...comparisonOverrides,
        ],
        child: const _TestApp(child: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing saved yet'), findsOneWidget);
  });

  testWidgets('shows saved places when favorites exist', (
    WidgetTester tester,
  ) async {
    testFavoriteIds = ['campuestohan', 'tom-n-toms'];
    testLocations = <Location>[
      _location(
        id: 'campuestohan',
        name: 'Campuestohan Highland Resort',
        address: 'Talisay, Negros Occidental',
        category: LocationCategory.activities,
        tags: const ['nature', 'family'],
      ),
      _location(
        id: 'tom-n-toms',
        name: 'Tom N Toms Lacson',
        address: 'Lacson Street, Bacolod',
        category: LocationCategory.coffee,
        tags: const ['wifi', 'coffee'],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteIdsProvider.overrideWith(TestFavoritesViewModel.new),
          favoriteLocationsProvider.overrideWith(
            (ref) async {
              final ids = await ref.watch(favoriteIdsProvider.future);
              return testLocations
                  .where((location) => ids.contains(location.id))
                  .toList(growable: false);
            },
          ),
          ...comparisonOverrides,
        ],
        child: const _TestApp(child: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campuestohan Highland Resort'), findsOneWidget);
    expect(find.text('Tom N Toms Lacson'), findsOneWidget);
  });
}

List<String> testFavoriteIds = const <String>[];
List<Location> testLocations = const <Location>[];

class TestFavoritesViewModel extends FavoritesViewModel {
  @override
  Future<List<String>> build() async => [...testFavoriteIds];

  @override
  Future<void> remove(String locationId) async {
    final updated = [...await future]..remove(locationId);
    state = AsyncData(updated);
  }

  @override
  Future<void> toggle(String locationId) async {
    final updated = [...await future];
    if (updated.contains(locationId)) {
      updated.remove(locationId);
    } else {
      updated.insert(0, locationId);
    }
    state = AsyncData(updated);
  }
}

class _StubComparisonViewModel extends LocationComparisonViewModel {
  @override
  Future<List<String>> build() async => const [];
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: SpontiTheme.light,
      home: child,
    );
  }
}

Location _location({
  required String id,
  required String name,
  required String address,
  required LocationCategory category,
  required List<String> tags,
}) {
  return Location(
    id: id,
    name: name,
    description: '$name description',
    category: category,
    coordinates: const Coordinates(latitude: 10.67, longitude: 122.95),
    address: address,
    priceRange: PriceRange.budget,
    photoUrls: const <String>[],
    tags: tags,
    createdAt: DateTime(2026, 3, 13),
  );
}
