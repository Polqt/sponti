import 'package:equatable/equatable.dart';

// Base class for all failures in the application.
// Used as the left side of [Either<Failure, T>]
sealed class Failure extends Equatable {
  const Failure([this.message = 'An unexpected error occurred.']);
  final String message;

  @override
  List<Object?> get props => [message];
}

// No internet connection failure
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'No internet connection. Please check your network settings.',
  ]);
}

// Supabase/backend related failure
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'A server error occurred. Please try again later.',
  ]);
}

// Local cache (Hive) related failure
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'A local storage error occurred. Please try again.',
  ]);
}

// Auth failure, e.g. invalid credentials, session expired, etc.
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Please check your credentials.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'You are not authorized to perform this action.',
  ]);
}

// Domain specific failures can be added here, e.g. UserFailure, PostFailure, etc.
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested resource was not found.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Invalid input. Please check your data and try again.',
  ]);
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure([
    super.message =
        'Location permission denied. Please grant permission to access location.',
  ]);
}
