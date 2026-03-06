import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

class GetAllLocationsParams extends Equatable {
  const GetAllLocationsParams({this.page = 0, this.pageSize = 20});

  final int page;
  final int pageSize;

  @override
  List<Object> get props => [page, pageSize];
}

@lazySingleton
class GetAllLocationsUseCase
    implements UseCase<List<Location>, GetAllLocationsParams> {
  const GetAllLocationsUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Either<Failure, List<Location>>> call(GetAllLocationsParams params) =>
      _repository.getAllLocations(page: params.page, pageSize: params.pageSize);
}
