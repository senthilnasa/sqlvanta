import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/connection_entity.dart';
import '../repositories/connection_repository.dart';

class TestConnection {
  final ConnectionRepository _repository;
  const TestConnection(this._repository);

  Future<Result<Duration, Failure>> call(
    ConnectionEntity entity,
    String password,
  ) => _repository.testConnection(entity, password);
}
