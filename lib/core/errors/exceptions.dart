/// Data-layer exceptions.
/// These are thrown by datasources and caught by repository implementations,
/// which convert them to [Failure] types using dartz [Either].
library;
// Data-layer exceptions.
// These are thrown by datasources and caught by repository implementations,
// which convert them to [Failure] types using dartz [Either].

class ServerException implements Exception {
  const ServerException([this.message = 'Server error.']);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection.']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error.']);
  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication error.']);
  final String message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found.']);
  final String message;
}

class LocationPermissionException implements Exception {
  const LocationPermissionException([
    this.message = 'Location permission denied.',
  ]);
  final String message;
}
