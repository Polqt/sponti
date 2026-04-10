import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/features/locations/model/location_query.dart';

void main() {
  group('LocationPageCursor', () {
    test('encodes and decodes a cursor round-trip', () {
      final original = LocationPageCursor(
        createdAt: DateTime.utc(2026, 4, 3, 12, 30),
        id: 'location-123',
      );

      final encoded = original.encode();
      final decoded = LocationPageCursor.tryParse(encoded);

      expect(decoded, original);
    });

    test('returns null for invalid cursor payload', () {
      expect(LocationPageCursor.tryParse('not-a-valid-cursor'), isNull);
    });
  });
}
