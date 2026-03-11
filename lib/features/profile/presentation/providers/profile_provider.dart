import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/dependency_injection.dart';
import 'package:sponti/features/auth/presentation/providers/auth_provider.dart';
import 'package:sponti/features/profile/domain/entities/user_profile.dart';
import 'package:sponti/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:sponti/features/profile/domain/usecases/get_user_stats_usecase.dart';
import 'package:sponti/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:sponti/features/profile/domain/usecases/upload_profile_photo_usecase.dart';

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    // Initially, we can return null or a loading state. Here, we choose to return null.
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return null;
    }

    // Fetch the profile for the current user
    final result = await getIt<GetUserProfileUseCase>()(user.id);
    return result.fold((_) => null, (profile) => profile);
  }

  Future<bool> updateProfile(UserProfile profile) async {
    final result = await getIt<UpdateProfileUseCase>()(profile);
    return result.fold((_) => false, (updated) {
      state = AsyncData(updated);
      return true;
    });
  }

  Future<bool> uploadPhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final urlResult = await getIt<UploadProfilePhotoUseCase>()(
      UploadProfilePhotoParams(
        userId: userId,
        bytes: bytes,
        extension: extension,
      ),
    );

    return urlResult.fold((_) => false, (url) async {
      final current = state.value;
      if (current == null) return false;
      return updateProfile(current.copyWith(avatarUrl: url));
    });
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);

/// Any users profile [for viewing other users profiles]
final userProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) async {
      final result = await getIt<GetUserProfileUseCase>()(userId);
      return result.fold((_) => null, (profile) => profile);
    });

// Stats
final userStatsProvider = FutureProvider.autoDispose.family<UserStats?, String>(
  (ref, userId) async {
    final result = await getIt<GetUserStatsUseCase>()(userId);
    return result.fold((_) => null, (stats) => stats);
  },
);
