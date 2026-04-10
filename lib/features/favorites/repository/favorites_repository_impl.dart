import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/base_repository.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/favorites/model/favorite.dart';
import 'package:sponti/features/favorites/repository/favorites_remote_data_source.dart';
import 'package:sponti/features/favorites/repository/favorites_repository.dart';
import 'package:sponti/features/locations/model/location.dart';

class FavoritesRepositoryImpl extends BaseRepository
    implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Favorite>>> getFavorites() =>
      guard(_remote.getFavorites);

  @override
  Future<Either<Failure, List<String>>> getFavoriteLocationIds() =>
      guard(() async {
        final favorites = await _remote.getFavorites();
        return favorites
            .map((favorite) => favorite.locationId)
            .toList(growable: false);
      });

  @override
  Future<Either<Failure, List<Location>>> getFavoriteLocations() =>
      guard(() async {
        final favorites = await _remote.getFavorites();
        return favorites
            .map((favorite) => favorite.location)
            .whereType<Location>()
            .toList(growable: false);
      });

  @override
  Future<Either<Failure, void>> addFavorite(String locationId) =>
      guard(() => _remote.addFavorite(locationId));

  @override
  Future<Either<Failure, void>> removeFavorite(String locationId) =>
      guard(() => _remote.removeFavorite(locationId));
}
