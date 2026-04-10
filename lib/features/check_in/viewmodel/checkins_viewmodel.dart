import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/repository/checkins_remote_data_source.dart';
import 'package:sponti/features/check_in/repository/checkins_repository.dart';
import 'package:sponti/features/check_in/repository/checkins_repository_impl.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:sponti/features/streaks/viewmodel/checkin_streak_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final checkinsRemoteDataSourceProvider = Provider<CheckinsRemoteDataSource>((
  ref,
) {
  return CheckinsRemoteDataSourceImpl(Supabase.instance.client);
});

final checkinsRepositoryProvider = Provider<CheckinsRepository>((ref) {
  return CheckinsRepositoryImpl(ref.read(checkinsRemoteDataSourceProvider));
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
  late final String _locationId;

  @override
  Future<CheckInState> build(String locationId) async {
    _locationId = locationId;
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
            locationId: _locationId,
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
    ref.invalidate(locationStreamProvider(_locationId));
  }
}

final checkInProvider =
    AsyncNotifierProviderFamily<CheckInNotifier, CheckInState, String>(
      CheckInNotifier.new,
    );

const _myCheckInsPageSize = 20;

class MyCheckInsNotifier extends AsyncNotifier<List<CheckIn>> {
  CheckInPageCursor? _nextCursor;
  bool _hasMore = false;
  bool _isFetchingNextPage = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<CheckIn>> build() async {
    _nextCursor = null;
    _hasMore = false;

    final repository = ref.read(checkinsRepositoryProvider);
    final result = await repository.getMyCheckInsPage(
      limit: _myCheckInsPageSize,
    );
    return result.fold(
      (failure) => throw StateError(failure.message),
      (page) {
        _hasMore = page.hasMore;
        _nextCursor = page.nextCursor;
        return page.items;
      },
    );
  }

  /// Returns an error message on failure, null on success.
  Future<String?> fetchNextPage() async {
    if (!_hasMore || _nextCursor == null || _isFetchingNextPage) return null;
    final current = state.valueOrNull;
    if (current == null) return null;

    _isFetchingNextPage = true;
    try {
      final repository = ref.read(checkinsRepositoryProvider);
      final result = await repository.getMyCheckInsPage(
        cursor: _nextCursor,
        limit: _myCheckInsPageSize,
      );
      return result.fold(
        (f) => f.message,
        (page) {
          _hasMore = page.hasMore;
          _nextCursor = page.nextCursor;
          state = AsyncData([...current, ...page.items]);
          return null;
        },
      );
    } finally {
      _isFetchingNextPage = false;
    }
  }
}

final myCheckInsProvider =
    AsyncNotifierProvider<MyCheckInsNotifier, List<CheckIn>>(
      MyCheckInsNotifier.new,
    );
