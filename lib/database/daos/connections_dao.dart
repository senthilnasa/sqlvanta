import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/connections_table.dart';

part 'connections_dao.g.dart';

@DriftAccessor(tables: [Connections])
class ConnectionsDao extends DatabaseAccessor<AppDatabase>
    with _$ConnectionsDaoMixin {
  ConnectionsDao(super.db);

  Future<List<Connection>> getAllConnections() =>
      (select(connections)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<Connection>> watchAllConnections() =>
      (select(connections)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<Connection?> getConnectionById(String id) =>
      (select(connections)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertConnection(ConnectionsCompanion companion) =>
      into(connections).insertOnConflictUpdate(companion);

  Future<int> deleteConnection(String id) =>
      (delete(connections)..where((t) => t.id.equals(id))).go();

  Future<void> updateLastConnected(String id) => (update(connections)
        ..where((t) => t.id.equals(id)))
      .write(ConnectionsCompanion(lastConnectedAt: Value(DateTime.now())));

  Future<int> getMaxSortOrder() async {
    final query = selectOnly(connections)
      ..addColumns([connections.sortOrder.max()]);
    final result = await query.getSingleOrNull();
    return result?.read(connections.sortOrder.max()) ?? 0;
  }
}
