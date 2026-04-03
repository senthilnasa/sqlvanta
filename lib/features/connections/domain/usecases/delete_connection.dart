import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/connection_repository.dart';

class DeleteConnection {
  final ConnectionRepository _repository;
  const DeleteConnection(this._repository);

  Future<Result<void, Failure>> call(String id) =>
      _repository.deleteConnection(id);
}
