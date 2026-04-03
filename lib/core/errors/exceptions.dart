// App-specific exception types thrown by the Data layer.
// These are caught at repository boundaries and converted to [Failure] values.

class DatabaseException implements Exception {
  final String message;
  final int? errorCode;
  const DatabaseException(this.message, {this.errorCode});

  @override
  String toString() => 'DatabaseException($errorCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
