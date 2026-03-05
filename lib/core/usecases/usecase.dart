// Base interface for all use cases.
// [Type] = the type of the result returned by the use case.
// [Params] = the type of the parameters required to execute the use case.
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sponti/core/errors/failures.dart';

abstract interface class Usecase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Use case with no parameters.
abstract interface class NoParamsUsecase<Type> {
  Future<Either<Failure, Type>> call();
}

// Use case with no return type (void).
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
