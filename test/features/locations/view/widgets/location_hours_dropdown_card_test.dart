import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/theme/app_theme.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/location_hours_dropdown_card.dart';

void main() {
  testWidgets('shows summary first and expands for extra hours details', (
    WidgetTester tester,
  ) async {
    const hours = OperatingHours(
      openTime: '08:00',
      closeTime: '17:00',
      daysOpen: <int>[1, 2, 3, 4, 5],
      specialNote: 'Holiday hours may vary.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: SpontiTheme.light,
        home: const Scaffold(
          body: LocationHoursDropdownCard(hours: hours),
        ),
      ),
    );

    expect(find.text('Opening hours'), findsOneWidget);
    expect(find.text('8:00 AM - 5:00 PM'), findsOneWidget);
    expect(find.text('Holiday hours may vary.'), findsNothing);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Holiday hours may vary.'), findsOneWidget);
  });
}
