import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

@lazySingleton
class CreateLocationUseCase implements UseCase<Location, Location> {
  const CreateLocationUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Either<Failure, Location>> call(Location location) =>
      _repository.createLocation(location);
}
