import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/exceptions.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/favorites/favorites_remote_data_source.dart';
import 'package:sponti/features/favorites/favorites_repository.dart';
import 'package:sponti/features/locations/model/location.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFavoriteLocationIds() =>
      _guard(_remote.getFavoriteLocationIds);

  @override
  Future<Either<Failure, List<Location>>> getFavoriteLocations() =>
      _guard(_remote.getFavoriteLocations);

  @override
  Future<Either<Failure, void>> addFavorite(String locationId) =>
      _guard(() => _remote.addFavorite(locationId));

  @override
  Future<Either<Failure, void>> removeFavorite(String locationId) =>
      _guard(() => _remote.removeFavorite(locationId));
}
