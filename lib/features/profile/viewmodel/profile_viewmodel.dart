import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/profile/model/user_profile.dart';
import 'package:sponti/features/profile/repository/profile_remote_data_source.dart';
import 'package:sponti/features/profile/repository/profile_repository.dart';
import 'package:sponti/features/profile/repository/profile_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(Supabase.instance.client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

class ProfileViewModel extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return null;
    }

    final result = await ref.read(profileRepositoryProvider).getUserProfile(
      user.id,
    );
    return result.fold((_) => null, (profile) => profile);
  }

  Future<bool> updateProfile(UserProfile profile) async {
    final result = await ref.read(profileRepositoryProvider).updateProfile(
      profile,
    );
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
    final urlResult = await ref.read(profileRepositoryProvider).uploadProfilePhoto(
      userId: userId,
      bytes: bytes,
      extension: extension,
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

final profileProvider = AsyncNotifierProvider<ProfileViewModel, UserProfile?>(
  ProfileViewModel.new,
);

final userProfileProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) async {
      final result = await ref.read(profileRepositoryProvider).getUserProfile(
        userId,
      );
      return result.fold((_) => null, (profile) => profile);
    });

final userStatsProvider = FutureProvider.autoDispose.family<UserStats?, String>(
  (ref, userId) async {
    final result = await ref.read(profileRepositoryProvider).getUserStats(
      userId,
    );
    return result.fold((_) => null, (stats) => stats);
  },
);
