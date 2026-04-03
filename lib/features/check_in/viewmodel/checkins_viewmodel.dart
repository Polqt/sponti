import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/repository/checkins_remote_data_source.dart';
import 'package:sponti/features/check_in/repository/checkins_repository.dart';
import 'package:sponti/features/check_in/repository/checkins_repository_impl.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:sponti/features/streaks/viewmodel/checkin_streak_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final checkinsRemoteDataSourceProvider = Provider<CheckinsRemoteDataSource>((
  ref,
) {
  return CheckinsRemoteDataSourceImpl(Supabase.instance.client);
});

final checkinsRepositoryProvider = Provider<CheckinsRepository>((ref) {
  return CheckinsRepositoryImpl(ref.watch(checkinsRemoteDataSourceProvider));
});

/// State for the check-in page tied to one location.
class CheckInState {
  const CheckInState({
    this.isCheckedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.checkIns = const [],
    this.myCheckInId,
    this.myCheckIn,
  });

  final bool isCheckedIn;
  final bool isLoading;
  final String? errorMessage;
  final List<CheckIn> checkIns;

  /// The ID of the current user's check-in row, used for deletion.
  final String? myCheckInId;
  final CheckIn? myCheckIn;

  CheckInState copyWith({
    bool? isCheckedIn,
    bool? isLoading,
    String? errorMessage,
    List<CheckIn>? checkIns,
    String? myCheckInId,
    CheckIn? myCheckIn,
    bool clearMyCheckInId = false,
    bool clearMyCheckIn = false,
  }) => CheckInState(
    isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    checkIns: checkIns ?? this.checkIns,
    myCheckInId: clearMyCheckInId ? null : (myCheckInId ?? this.myCheckInId),
    myCheckIn: clearMyCheckIn ? null : (myCheckIn ?? this.myCheckIn),
  );
}

/// Notifier scoped to a single location.
/// Pass the locationId via the family parameter.
class CheckInNotifier extends FamilyAsyncNotifier<CheckInState, String> {
  @override
  Future<CheckInState> build(String locationId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const CheckInState();

    final repo = ref.read(checkinsRepositoryProvider);

    final results = await Future.wait([
      repo.hasUserCheckedIn(locationId, userId),
      repo.getCheckInsForLocation(locationId),
    ]);

    final hasCheckedIn = results[0].fold((_) => false, (v) => v as bool);
    final checkIns = results[1].fold(
      (_) => <CheckIn>[],
      (v) => v as List<CheckIn>,
    );

    // Find the user's own check-in to get its id for potential deletion.
    String? myCheckInId;
    CheckIn? myCheckIn;
    if (hasCheckedIn) {
      final mine = checkIns.where((c) => c.userId == userId).toList();
      if (mine.isNotEmpty) {
        final currentUserCheckIn = mine.first;
        myCheckIn = currentUserCheckIn;
        myCheckInId = currentUserCheckIn.id;
      }
    }

    return CheckInState(
      isCheckedIn: hasCheckedIn,
      checkIns: checkIns,
      myCheckInId: myCheckInId,
      myCheckIn: myCheckIn,
    );
  }

  /// Submit a new check-in with optional note and photos.
  Future<bool> checkIn({String? note, List<String> photos = const []}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;

    final current = state.valueOrNull ?? const CheckInState();
    state = AsyncData(
      current.copyWith(
        isLoading: true,
        isCheckedIn: true,
        errorMessage: null,
      ),
    );

    final repository = ref.read(checkinsRepositoryProvider);
    final result = current.myCheckInId == null
        ? await repository.createCheckIn(
            locationId: arg,
            userId: userId,
            note: note,
            photos: photos,
          )
        : await repository.updateCheckIn(
            checkInId: current.myCheckInId!,
            note: note,
            photos: photos,
          );

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: failure.message),
        );
        return false;
      },
      (checkIn) {
        final updatedCheckIns = [
          checkIn,
          ...current.checkIns.where((item) => item.id != checkIn.id),
        ];
        state = AsyncData(
          current.copyWith(
            isLoading: false,
            isCheckedIn: true,
            myCheckInId: checkIn.id,
            myCheckIn: checkIn,
            checkIns: updatedCheckIns,
          ),
        );
        _invalidateDependentProviders();
        return true;
      },
    );
  }

  /// Delete the current user's check-in (undo check-in).
  Future<bool> deleteCheckIn() async {
    final current = state.valueOrNull ?? const CheckInState();
    final checkInId = current.myCheckInId;
    if (checkInId == null) return false;

    state = AsyncData(
      current.copyWith(
        isLoading: true,
        isCheckedIn: false,
        errorMessage: null,
      ),
    );

    final result = await ref
        .read(checkinsRepositoryProvider)
        .deleteCheckIn(checkInId);

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: failure.message),
        );
        return false;
      },
      (_) {
        final userId = ref.read(currentUserIdProvider);
        state = AsyncData(
          current.copyWith(
            isLoading: false,
            isCheckedIn: false,
            clearMyCheckInId: true,
            clearMyCheckIn: true,
            checkIns: current.checkIns
                .where((c) => c.id != checkInId && c.userId != userId)
                .toList(),
          ),
        );
        _invalidateDependentProviders();
        return true;
      },
    );
  }

  void _invalidateDependentProviders() {
    // Invalidate stats only - profile data hasn't changed, just the check-in count
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      ref.invalidate(userStatsProvider(userId));
    }
    ref.invalidate(myCheckInsProvider);
    ref.invalidate(checkInStreakProvider);
  }
}

final checkInProvider =
    AsyncNotifierProviderFamily<CheckInNotifier, CheckInState, String>(
      CheckInNotifier.new,
    );

final myCheckInsProvider = FutureProvider<List<CheckIn>>((ref) async {
  final result = await ref.read(checkinsRepositoryProvider).getMyCheckIns();
  return result.fold((failure) {
    throw StateError(failure.message);
  }, (checkIns) => checkIns);
});
