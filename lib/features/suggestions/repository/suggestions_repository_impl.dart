import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/features/suggestions/repository/suggestions_remote_data_source.dart';
import 'package:sponti/features/suggestions/model/suggestion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

sealed class SuggestionFailure {
  const SuggestionFailure(this.message);
  final String message;
}

class SuggestionAuthFailure extends SuggestionFailure {
  const SuggestionAuthFailure(super.message);
}

class SuggestionNetworkFailure extends SuggestionFailure {
  const SuggestionNetworkFailure(super.message);
}

class SuggestionNotFoundFailure extends SuggestionFailure {
  const SuggestionNotFoundFailure(super.message);
}

class SuggestionUnknownFailure extends SuggestionFailure {
  const SuggestionUnknownFailure(super.message);
}

abstract interface class SuggestionsRepository {
  Future<Either<SuggestionFailure, List<SuggestionModel>>> fetchMySuggestions();
  Future<Either<SuggestionFailure, SuggestionModel>> fetchSuggestionById(
    String id,
  );
  Future<Either<SuggestionFailure, Unit>> insertSuggestion(
    SuggestionModel suggestion,
  );
  Future<Either<SuggestionFailure, Unit>> updateSuggestion(
    SuggestionModel suggestion,
  );
  Future<Either<SuggestionFailure, Unit>> deleteSuggestion(String id);
}

class SuggestionsRepositoryImpl implements SuggestionsRepository {
  const SuggestionsRepositoryImpl(this._dataSource);

  final SuggestionsRemoteDataSource _dataSource;

  SuggestionFailure _mapError(Object e) {
    if (e is AuthException) {
      return const SuggestionAuthFailure('you must be logged in');
    }
    if (e is PostgrestException) {
      return SuggestionNetworkFailure(e.message);
    }
    return SuggestionUnknownFailure(e.toString());
  }

  @override
  Future<Either<SuggestionFailure, List<SuggestionModel>>>
      fetchMySuggestions() async {
    try {
      return Right(await _dataSource.fetchMySuggestions());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<SuggestionFailure, SuggestionModel>> fetchSuggestionById(
    String id,
  ) async {
    try {
      return Right(await _dataSource.fetchSuggestionById(id));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left(SuggestionNotFoundFailure('suggestion not found'));
      }
      return Left(_mapError(e));
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<SuggestionFailure, Unit>> insertSuggestion(
    SuggestionModel suggestion,
  ) async {
    try {
      await _dataSource.insertSuggestion(suggestion);
      return const Right(unit);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<SuggestionFailure, Unit>> updateSuggestion(
    SuggestionModel suggestion,
  ) async {
    try {
      await _dataSource.updateSuggestion(suggestion);
      return const Right(unit);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<SuggestionFailure, Unit>> deleteSuggestion(String id) async {
    try {
      await _dataSource.deleteSuggestion(id);
      return const Right(unit);
    } catch (e) {
      return Left(_mapError(e));
    }
  }
}
