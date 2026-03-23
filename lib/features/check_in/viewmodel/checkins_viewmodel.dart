import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/check_in/models/checkins.dart';
import 'package:sponti/features/check_in/repository/checkins_remote_data_source.dart';
import 'package:sponti/features/check_in/repository/checkins_repository.dart';
import 'package:sponti/features/check_in/repository/checkins_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final checkinsRemoteDataSourceProvider =
    Provider<CheckinsRemoteDataSource>((ref) {
  return CheckinsRemoteDataSourceImpl(Supabase.instance.client);
});

final checkinsRepositoryProvider = Provider<CheckinsRepository>((ref) {
  return CheckinsRepositoryImpl(
    ref.watch(checkinsRemoteDataSourceProvider),
  );
});

// ── Per-location check-in state ───────────────────────────────────────────────

/// State for the check-in sheet tied to one location.
class CheckInState {
  const CheckInState({
    this.isCheckedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.checkIns = const [],
  });

  final bool isCheckedIn;
  final bool isLoading;
  final String? errorMessage;
  final List<CheckIn> checkIns;

  CheckInState copyWith({
    bool? isCheckedIn,
    bool? isLoading,
    String? errorMessage,
    List<CheckIn>? checkIns,
  }) => CheckInState(
    isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    checkIns: checkIns ?? this.checkIns,
  );
}

/// Notifier scoped to a single location.
/// Pass the locationId via the family parameter.
class CheckInNotifier extends FamilyAsyncNotifier<CheckInState, String> {
  @override
  Future<CheckInState> build(String locationId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const CheckInState();

    final repo = ref.read(checkinsRepositoryProvider);

    final results = await Future.wait([
      repo.hasUserCheckedIn(locationId, userId),
      repo.getCheckInsForLocation(locationId),
    ]);

    final hasCheckedIn =
        results[0].fold((_) => false, (v) => v as bool);
    final checkIns =
        results[1].fold((_) => <CheckIn>[], (v) => v as List<CheckIn>);

    return CheckInState(isCheckedIn: hasCheckedIn, checkIns: checkIns);
  }

  /// Submit a new check-in with optional note.
  Future<bool> checkIn({String? note}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    final current = state.valueOrNull ?? const CheckInState();
    state = AsyncData(current.copyWith(isLoading: true));

    final result = await ref.read(checkinsRepositoryProvider).createCheckIn(
      locationId: arg,
      userId: userId,
      note: note,
    );

    return result.fold(
      (failure) {
        state = AsyncData(
          current.copyWith(isLoading: false, errorMessage: failure.message),
        );
        return false;
      },
      (checkIn) {
        state = AsyncData(
          current.copyWith(
            isLoading: false,
            isCheckedIn: true,
            checkIns: [checkIn, ...current.checkIns],
          ),
        );
        return true;
      },
    );
  }
}

final checkInProvider = AsyncNotifierProviderFamily<
    CheckInNotifier, CheckInState, String>(CheckInNotifier.new);
