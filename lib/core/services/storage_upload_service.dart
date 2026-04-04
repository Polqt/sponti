import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sponti/config/supabase_options.dart';
import 'package:sponti/core/utils/image_upload.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LocationPhotoUploadFolder {
  reviews('reviews'),
  checkIns('check_ins');

  const LocationPhotoUploadFolder(this.segment);

  final String segment;
}

class StorageUploadResult {
  const StorageUploadResult({
    this.uploadedUrls = const <String>[],
    this.failedMessages = const <String>[],
  });

  final List<String> uploadedUrls;
  final List<String> failedMessages;
}

String buildLocationPhotoObjectPath({
  required LocationPhotoUploadFolder folder,
  required String userId,
  required String locationId,
  required String extension,
  String? filenameSuffix,
  DateTime? timestamp,
}) {
  final normalizedExtension = extension.startsWith('.')
      ? extension.substring(1)
      : extension;
  final now = timestamp ?? DateTime.now();
  final suffix = filenameSuffix == null || filenameSuffix.isEmpty
      ? ''
      : '_$filenameSuffix';

  return '${folder.segment}/$userId/$locationId/${now.microsecondsSinceEpoch}$suffix.$normalizedExtension';
}

abstract interface class StorageUploadService {
  Future<StorageUploadResult> uploadLocationPhotos({
    required List<XFile> files,
    required String locationId,
    required LocationPhotoUploadFolder folder,
  });
}

class SupabaseStorageUploadService implements StorageUploadService {
  const SupabaseStorageUploadService(this._client);

  final SupabaseClient _client;

  @override
  Future<StorageUploadResult> uploadLocationPhotos({
    required List<XFile> files,
    required String locationId,
    required LocationPhotoUploadFolder folder,
  }) async {
    if (files.isEmpty) {
      return const StorageUploadResult();
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const StorageUploadResult(
        failedMessages: <String>[
          'You must be signed in to upload photos.',
        ],
      );
    }

    final uploadedUrls = <String>[];
    final failedMessages = <String>[];

    for (var index = 0; index < files.length; index++) {
      final result = await _uploadSingle(
        file: files[index],
        userId: userId,
        locationId: locationId,
        folder: folder,
        suffixIndex: index,
      );

      final uploadedUrl = result.$1;
      final errorMessage = result.$2;

      if (uploadedUrl != null) {
        uploadedUrls.add(uploadedUrl);
        continue;
      }

      if (errorMessage != null && !failedMessages.contains(errorMessage)) {
        failedMessages.add(errorMessage);
      }
    }

    return StorageUploadResult(
      uploadedUrls: List.unmodifiable(uploadedUrls),
      failedMessages: List.unmodifiable(failedMessages),
    );
  }

  Future<(String?, String?)> _uploadSingle({
    required XFile file,
    required String userId,
    required String locationId,
    required LocationPhotoUploadFolder folder,
    required int suffixIndex,
  }) async {
    try {
      final contentType = imageContentTypeForPath(file.path);
      if (contentType == null) {
        return (null, 'Unsupported file type. Use JPG, PNG, or WEBP.');
      }

      final extension = contentType.split('/').last;
      final path = buildLocationPhotoObjectPath(
        folder: folder,
        userId: userId,
        locationId: locationId,
        extension: extension,
        filenameSuffix: suffixIndex == 0 ? null : '$suffixIndex',
      );

      await _client.storage.from(SupabaseBuckets.locationPhotos).uploadBinary(
            path,
            await File(file.path).readAsBytes(),
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final optimization = await _optimizeLocationPhoto(path);
      final resolvedPath = optimization.$1 ?? path;
      final url = _client.storage
          .from(SupabaseBuckets.locationPhotos)
          .getPublicUrl(resolvedPath);
      return (url, optimization.$2);
    } on StorageException catch (error) {
      return (null, error.message);
    } catch (error) {
      return (null, error.toString());
    }
  }

  Future<(String?, String?)> _optimizeLocationPhoto(String objectPath) async {
    try {
      final response = await _client.functions.invoke(
        SupabaseEdgeFunctions.optimizeUploadedImage,
        body: {
          'bucket': SupabaseBuckets.locationPhotos,
          'path': objectPath,
        },
      );
      final data = response.data;
      if (data is! Map) {
        return (null, 'Image uploaded but optimization response was invalid.');
      }
      final optimizedPath = data['optimized_path'];
      if (optimizedPath is String && optimizedPath.isNotEmpty) {
        return (optimizedPath, null);
      }
      return (null, 'Image uploaded but optimization response was invalid.');
    } on FunctionException catch (error) {
      return (null, 'Image uploaded but optimization failed: ${error.details ?? error.reasonPhrase ?? 'unknown error'}');
    } catch (error) {
      return (null, 'Image uploaded but optimization failed: $error');
    }
  }
}

final storageUploadServiceProvider = Provider<StorageUploadService>((ref) {
  return SupabaseStorageUploadService(Supabase.instance.client);
});
