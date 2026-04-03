import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/connection_entity.dart';
import '../repositories/connection_repository.dart';

class GetAllConnections {
  final ConnectionRepository _repository;
  const GetAllConnections(this._repository);

  Future<Result<List<ConnectionEntity>, Failure>> call() =>
      _repository.getAllConnections();
}
