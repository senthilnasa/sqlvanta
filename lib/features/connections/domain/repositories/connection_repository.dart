import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/connection_entity.dart';

abstract interface class ConnectionRepository {
  Future<Result<List<ConnectionEntity>, Failure>> getAllConnections();

  Future<Result<ConnectionEntity, Failure>> getConnectionById(String id);

  Future<Result<void, Failure>> saveConnection(
    ConnectionEntity entity,
    String password,
  );

  Future<Result<void, Failure>> deleteConnection(String id);

  Future<Result<String, Failure>> getPassword(String connectionId);

  Future<Result<Duration, Failure>> testConnection(
    ConnectionEntity entity,
    String password,
  );
}
