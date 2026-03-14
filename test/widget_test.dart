import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/theme/app_theme.dart';
import 'package:sponti/features/favorites/favorites_viewmodel.dart';
import 'package:sponti/features/favorites/view/screens/favorites_screen.dart';
import 'package:sponti/features/locations/model/coordinates.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

void main() {
  testWidgets('shows empty state when there are no saved places', (
    WidgetTester tester,
  ) async {
    testFavoriteIds = const <String>[];
    testLocations = const <Location>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteIdsProvider.overrideWith(TestFavoritesViewModel.new),
          locationsProvider.overrideWith(TestLocationsViewModel.new),
        ],
        child: const _TestApp(child: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved places yet'), findsOneWidget);
    expect(find.text('Explore spots'), findsOneWidget);
  });

  testWidgets('filters and removes saved places', (WidgetTester tester) async {
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
          locationsProvider.overrideWith(TestLocationsViewModel.new),
        ],
        child: const _TestApp(child: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campuestohan Highland Resort'), findsOneWidget);
    expect(find.text('Tom N Toms Lacson'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'coffee');
    await tester.pumpAndSettle();

    expect(find.text('Campuestohan Highland Resort'), findsNothing);
    expect(find.text('Tom N Toms Lacson'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Tom N Toms Lacson'), findsNothing);
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

class TestLocationsViewModel extends LocationsViewModel {
  @override
  Future<List<Location>> build() async => [...testLocations];
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
