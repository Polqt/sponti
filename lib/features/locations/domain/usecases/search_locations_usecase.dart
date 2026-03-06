import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

@lazySingleton
class SearchLocationsUseCase implements UseCase<List<Location>, String> {
  const SearchLocationsUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Either<Failure, List<Location>>> call(String query) =>
  _repository.searchLocations(query);
}
