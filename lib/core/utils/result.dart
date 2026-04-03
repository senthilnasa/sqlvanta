/// A discriminated union representing either a successful value [S]
/// or a failure value [F]. Use [Result.success] and [Result.failure]
/// constructors, then call [fold] or check [isSuccess]/[isFailure].
sealed class Result<S, F> {
  const Result();

  const factory Result.success(S value) = ResultSuccess<S, F>;
  const factory Result.failure(F error) = ResultFailure<S, F>;

  bool get isSuccess => this is ResultSuccess<S, F>;
  bool get isFailure => this is ResultFailure<S, F>;

  S get value => (this as ResultSuccess<S, F>).value;
  F get error => (this as ResultFailure<S, F>).error;

  T fold<T>({
    required T Function(S value) onSuccess,
    required T Function(F error) onFailure,
  }) {
    return switch (this) {
      ResultSuccess(:final value) => onSuccess(value),
      ResultFailure(:final error) => onFailure(error),
    };
  }

  Result<T, F> map<T>(T Function(S value) transform) {
    return switch (this) {
      ResultSuccess(:final value) => Result.success(transform(value)),
      ResultFailure(:final error) => Result.failure(error),
    };
  }
}

final class ResultSuccess<S, F> extends Result<S, F> {
  @override
  final S value;
  const ResultSuccess(this.value);
}

final class ResultFailure<S, F> extends Result<S, F> {
  @override
  final F error;
  const ResultFailure(this.error);
}
