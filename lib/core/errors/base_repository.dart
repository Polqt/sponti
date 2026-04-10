import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';

/// Base class for all repositories providing shared error handling.
///
/// Repositories should extend this class and use [guard] to wrap
/// data source calls with consistent exception-to-failure conversion.
abstract class BaseRepository {
  const BaseRepository();

  /// Wraps a data source call with standard exception handling.
  ///
  /// Converts known exceptions to their corresponding [Failure] types:
  /// - [AuthException] → [AuthFailure]
  /// - [NotFoundException] → [NotFoundFailure]
  /// - [ServerException] → [ServerFailure]
  /// - [NetworkException] → [NetworkFailure]
  /// - [CacheException] → [CacheFailure]
  /// - Unknown exceptions → [ServerFailure]
  Future<Either<Failure, T>> guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
