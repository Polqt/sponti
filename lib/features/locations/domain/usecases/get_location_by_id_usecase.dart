import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

@lazySingleton
class GetLocationByIdUseCase implements UseCase<Location, String> {
  const GetLocationByIdUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Either<Failure, Location>> call(String id) =>
      _repository.getLocationById(id);
}
