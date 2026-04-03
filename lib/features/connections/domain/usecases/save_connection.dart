import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/connection_entity.dart';
import '../repositories/connection_repository.dart';

class SaveConnection {
  final ConnectionRepository _repository;
  const SaveConnection(this._repository);

  Future<Result<void, Failure>> call(
    ConnectionEntity entity,
    String password,
  ) => _repository.saveConnection(entity, password);
}
