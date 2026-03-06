import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

@lazySingleton
class DeleteLocationUseCase implements UseCase<void, String> {
  const DeleteLocationUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Either<Failure, void>> call(String id) =>
      _repository.deleteLocation(id);
}
