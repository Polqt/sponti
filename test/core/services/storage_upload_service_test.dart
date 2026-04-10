import 'package:flutter_test/flutter_test.dart';
import 'package:sponti/core/services/storage_upload_service.dart';

void main() {
  group('buildLocationPhotoObjectPath', () {
    test('builds deterministic path for review uploads', () {
      final path = buildLocationPhotoObjectPath(
        folder: LocationPhotoUploadFolder.reviews,
        userId: 'user-123',
        locationId: 'loc-456',
        extension: 'jpg',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1710000000000),
      );

      expect(path, 'reviews/user-123/loc-456/1710000000000000.jpg');
    });

    test('adds optional suffix without changing folder structure', () {
      final path = buildLocationPhotoObjectPath(
        folder: LocationPhotoUploadFolder.checkIns,
        userId: 'user-123',
        locationId: 'loc-456',
        extension: '.webp',
        filenameSuffix: '2',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1710000000000),
      );

      expect(path, 'check_ins/user-123/loc-456/1710000000000000_2.webp');
    });
  });
}
