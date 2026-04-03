/// Sealed class hierarchy for all application-level failures.
/// Used as the [F] type in [Result<S, F>].
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// MySQL/database communication error (connection refused, query error, etc.)
final class DatabaseFailure extends Failure {
  final int? errorCode;
  const DatabaseFailure(super.message, {this.errorCode});
}

/// Network-level error (host unreachable, DNS failure, timeout)
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// SSH tunnel error
final class SshFailure extends Failure {
  const SshFailure(super.message);
}

/// Authentication error (wrong credentials, plugin unsupported)
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Local storage error (Drift, file I/O)
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Validation error (invalid form input)
final class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}

/// Unexpected / unhandled error
final class UnexpectedFailure extends Failure {
  final Object? originalException;
  const UnexpectedFailure(super.message, {this.originalException});
}
