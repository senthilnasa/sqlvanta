import 'package:drift/drift.dart';

import '../../../../database/daos/connections_dao.dart';
import '../models/connection_model.dart';
import '../../domain/entities/connection_entity.dart';

class ConnectionLocalDatasource {
  final ConnectionsDao _dao;
  const ConnectionLocalDatasource(this._dao);

  Future<List<ConnectionEntity>> getAllConnections() async {
    final rows = await _dao.getAllConnections();
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<ConnectionEntity?> getConnectionById(String id) async {
    final row = await _dao.getConnectionById(id);
    return row?.toEntity();
  }

  Future<void> upsertConnection(
    ConnectionEntity entity,
    String passwordKey,
  ) async {
    final companion = entity.toCompanion();
    // Ensure the passwordKey stored matches the secure-storage key
    await _dao.upsertConnection(
      companion.copyWith(passwordKey: Value(passwordKey)),
    );
  }

  Future<void> deleteConnection(String id) => _dao.deleteConnection(id);

  Future<void> updateLastConnected(String id) => _dao.updateLastConnected(id);

  Future<int> getMaxSortOrder() => _dao.getMaxSortOrder();
}
