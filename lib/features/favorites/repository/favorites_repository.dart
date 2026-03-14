import 'package:dartz/dartz.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/features/favorites/model/favorite.dart';
import 'package:sponti/features/locations/model/location.dart';

abstract interface class FavoritesRepository {
  Future<Either<Failure, List<Favorite>>> getFavorites();
  Future<Either<Failure, List<String>>> getFavoriteLocationIds();
  Future<Either<Failure, List<Location>>> getFavoriteLocations();
  Future<Either<Failure, void>> addFavorite(String locationId);
  Future<Either<Failure, void>> removeFavorite(String locationId);
}
