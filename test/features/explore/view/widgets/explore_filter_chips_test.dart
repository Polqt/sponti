import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/theme/app_theme.dart';
import 'package:sponti/features/explore/view/widgets/explore_filter_chips.dart';
import 'package:sponti/features/explore/viewmodel/explore_viewmodel.dart';

void main() {
  testWidgets('renders chip labels and forwards interactions', (
    WidgetTester tester,
  ) async {
    var rankingTapped = false;
    var priceTapped = false;
    var categoryTapped = false;
    var nowOpenTapped = false;
    var amenitiesTapped = false;

    // Use a wide surface so all chips fit without scrolling.
    tester.view.physicalSize = const Size(1600, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: SpontiTheme.light,
        home: Scaffold(
          body: ExploreFilterChips(
            filter: const ExploreFilter(),
            onTapRanking: () => rankingTapped = true,
            onTapPrice: () => priceTapped = true,
            onTapCategory: () => categoryTapped = true,
            onToggleNowOpen: () => nowOpenTapped = true,
            onTapAmenities: () => amenitiesTapped = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('Trending'), findsOneWidget);
    expect(find.text('Any price'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Now open'), findsOneWidget);
    expect(find.text('Amenities'), findsOneWidget);

    await tester.tap(find.textContaining('Trending'));
    await tester.pump();
    expect(rankingTapped, isTrue);

    await tester.tap(find.text('Any price'));
    await tester.pump();
    expect(priceTapped, isTrue);

    await tester.tap(find.text('Category'));
    await tester.pump();
    expect(categoryTapped, isTrue);

    await tester.tap(find.text('Now open'));
    await tester.pump();
    expect(nowOpenTapped, isTrue);

    await tester.tap(find.text('Amenities'));
    await tester.pump();
    expect(amenitiesTapped, isTrue);
  });
}
