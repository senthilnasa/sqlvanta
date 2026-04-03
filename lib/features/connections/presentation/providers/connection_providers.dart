import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../database/app_database.dart';
import '../../../../mysql/mysql_client_factory.dart';
import '../../../../mysql/mysql_connection_tester.dart';
import '../../data/datasources/connection_local_datasource.dart';
import '../../data/datasources/connection_secure_storage.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../domain/entities/connection_entity.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/usecases/delete_connection.dart';
import '../../domain/usecases/get_all_connections.dart';
import '../../domain/usecases/save_connection.dart';
import '../../domain/usecases/test_connection.dart';

part 'connection_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) => AppDatabase();

@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) =>
    const FlutterSecureStorage();

// ── Data layer ────────────────────────────────────────────────────────────────

@riverpod
ConnectionLocalDatasource connectionLocalDatasource(
  ConnectionLocalDatasourceRef ref,
) => ConnectionLocalDatasource(ref.watch(appDatabaseProvider).connectionsDao);

@riverpod
ConnectionSecureStorage connectionSecureStorage(
  ConnectionSecureStorageRef ref,
) => ConnectionSecureStorage(ref.watch(secureStorageProvider));

@riverpod
MysqlClientFactory mysqlClientFactory(MysqlClientFactoryRef ref) =>
    const MysqlClientFactory();

@riverpod
MysqlConnectionTester mysqlConnectionTester(MysqlConnectionTesterRef ref) =>
    MysqlConnectionTester(ref.watch(mysqlClientFactoryProvider));

@riverpod
ConnectionRepository connectionRepository(ConnectionRepositoryRef ref) =>
    ConnectionRepositoryImpl(
      ref.watch(connectionLocalDatasourceProvider),
      ref.watch(connectionSecureStorageProvider),
      ref.watch(mysqlConnectionTesterProvider),
    );

// ── Use cases ─────────────────────────────────────────────────────────────────

@riverpod
GetAllConnections getAllConnections(GetAllConnectionsRef ref) =>
    GetAllConnections(ref.watch(connectionRepositoryProvider));

@riverpod
SaveConnection saveConnection(SaveConnectionRef ref) =>
    SaveConnection(ref.watch(connectionRepositoryProvider));

@riverpod
DeleteConnection deleteConnection(DeleteConnectionRef ref) =>
    DeleteConnection(ref.watch(connectionRepositoryProvider));

@riverpod
TestConnection testConnection(TestConnectionRef ref) =>
    TestConnection(ref.watch(connectionRepositoryProvider));

// ── Connection list notifier ──────────────────────────────────────────────────

@riverpod
class ConnectionList extends _$ConnectionList {
  @override
  Future<List<ConnectionEntity>> build() async {
    final result = await ref.watch(getAllConnectionsProvider).call();
    return result.fold(
      onSuccess: (list) => list,
      onFailure: (f) => throw Exception(f.message),
    );
  }

  Future<void> save(ConnectionEntity entity, String password) async {
    final result = await ref
        .read(saveConnectionProvider)
        .call(entity, password);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (f) => throw Exception(f.message),
    );
  }

  Future<void> remove(String id) async {
    final result = await ref.read(deleteConnectionProvider).call(id);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (f) => throw Exception(f.message),
    );
  }

  Future<Result<Duration, Failure>> test(
    ConnectionEntity entity,
    String password,
  ) => ref.read(testConnectionProvider).call(entity, password);
}

// ── Selected connection ───────────────────────────────────────────────────────

@riverpod
class SelectedConnectionId extends _$SelectedConnectionId {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}
