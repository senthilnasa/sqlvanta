import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../database/app_database.dart';
import '../../../../database/daos/query_history_dao.dart';
import '../../domain/entities/query_history_entry.dart';

class QueryHistoryDatasource {
  final QueryHistoryDao _dao;
  const QueryHistoryDatasource(this._dao);

  Future<List<QueryHistoryEntry>> getRecent({
    required String connectionId,
    int limit = 100,
  }) async {
    final rows = await _dao.getRecentHistory(
      connectionId: connectionId,
      limit: limit,
    );
    return rows
        .map(
          (r) => QueryHistoryEntry(
            id: r.id,
            connectionId: r.connectionId,
            databaseName: r.databaseName,
            sqlText: r.sqlText,
            executedAt: r.executedAt,
            durationMs: r.durationMs,
            rowsAffected: r.rowsAffected,
            hadError: r.hadError,
            errorMessage: r.errorMessage,
            isFavorite: r.isFavorite,
          ),
        )
        .toList();
  }

  Future<void> insert({
    required String connectionId,
    String? databaseName,
    required String sqlText,
    required int durationMs,
    int? rowsAffected,
    bool hadError = false,
    String? errorMessage,
  }) => _dao.insertEntry(
    QueryHistoryCompanion.insert(
      id: const Uuid().v4(),
      connectionId: connectionId,
      databaseName: Value(databaseName),
      sqlText: sqlText,
      durationMs: durationMs,
      rowsAffected: Value(rowsAffected),
      hadError: Value(hadError),
      errorMessage: Value(errorMessage),
    ),
  );
}
