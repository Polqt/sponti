import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:sponti/core/errors/failures.dart';
import 'package:sponti/core/usecases/usecase.dart';
import 'package:sponti/features/locations/domain/entities/location.dart';
import 'package:sponti/features/locations/domain/repositories/location_repository.dart';

class GetNearbyLocationsParams extends Equatable {
  const GetNearbyLocationsParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;

  @override
  List<Object> get props => [latitude, longitude, radiusKm];
}

@lazySingleton
class GetNearbyLocationsUseCase
    implements UseCase<List<Location>, GetNearbyLocationsParams> {
  const GetNearbyLocationsUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Either<Failure, List<Location>>> call(
    GetNearbyLocationsParams params,
  ) => _repository.getNearbyLocations(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
  );
}
