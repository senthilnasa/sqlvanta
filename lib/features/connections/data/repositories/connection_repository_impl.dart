import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../mysql/mysql_connection_tester.dart';
import '../../domain/entities/connection_entity.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/connection_local_datasource.dart';
import '../datasources/connection_secure_storage.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionLocalDatasource _local;
  final ConnectionSecureStorage _secure;
  final MysqlConnectionTester _tester;

  const ConnectionRepositoryImpl(this._local, this._secure, this._tester);

  @override
  Future<Result<List<ConnectionEntity>, Failure>> getAllConnections() async {
    try {
      final list = await _local.getAllConnections();
      return Result.success(list);
    } catch (e, st) {
      AppLogger.error('getAllConnections failed', error: e, stackTrace: st);
      return Result.failure(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<ConnectionEntity, Failure>> getConnectionById(
      String id) async {
    try {
      final entity = await _local.getConnectionById(id);
      if (entity == null) {
        return Result.failure(
            const StorageFailure('Connection not found'));
      }
      return Result.success(entity);
    } catch (e, st) {
      AppLogger.error('getConnectionById failed', error: e, stackTrace: st);
      return Result.failure(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> saveConnection(
    ConnectionEntity entity,
    String password,
  ) async {
    try {
      final id = entity.id.isEmpty ? const Uuid().v4() : entity.id;
      final withId = entity.copyWith(id: id);
      final passwordKey = id;
      await _secure.savePassword(id, password);
      await _local.upsertConnection(withId, passwordKey);
      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('saveConnection failed', error: e, stackTrace: st);
      return Result.failure(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteConnection(String id) async {
    try {
      await _local.deleteConnection(id);
      await _secure.deletePassword(id);
      return const Result.success(null);
    } catch (e, st) {
      AppLogger.error('deleteConnection failed', error: e, stackTrace: st);
      return Result.failure(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<String, Failure>> getPassword(String connectionId) async {
    try {
      final pw = await _secure.getPassword(connectionId);
      if (pw == null) {
        return Result.failure(
            const StorageFailure('Password not found in secure storage'));
      }
      return Result.success(pw);
    } catch (e, st) {
      AppLogger.error('getPassword failed', error: e, stackTrace: st);
      return Result.failure(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<Duration, Failure>> testConnection(
    ConnectionEntity entity,
    String password,
  ) async {
    try {
      final duration = await _tester.test(entity, password);
      return Result.success(duration);
    } on Exception catch (e) {
      return Result.failure(NetworkFailure(e.toString()));
    } catch (e, st) {
      AppLogger.error('testConnection failed', error: e, stackTrace: st);
      return Result.failure(UnexpectedFailure(e.toString()));
    }
  }
}
