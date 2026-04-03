import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/query_history_table.dart';

part 'query_history_dao.g.dart';

@DriftAccessor(tables: [QueryHistory])
class QueryHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$QueryHistoryDaoMixin {
  QueryHistoryDao(super.db);

  Future<List<QueryHistoryData>> getRecentHistory({
    required String connectionId,
    int limit = 100,
  }) =>
      (select(queryHistory)
            ..where((t) => t.connectionId.equals(connectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.executedAt)])
            ..limit(limit))
          .get();

  Stream<List<QueryHistoryData>> watchRecentHistory({
    required String connectionId,
    int limit = 100,
  }) =>
      (select(queryHistory)
            ..where((t) => t.connectionId.equals(connectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.executedAt)])
            ..limit(limit))
          .watch();

  Future<void> insertEntry(QueryHistoryCompanion companion) =>
      into(queryHistory).insert(companion);

  Future<int> deleteForConnection(String connectionId) =>
      (delete(queryHistory)
        ..where((t) => t.connectionId.equals(connectionId))).go();

  Future<void> toggleFavorite(String id, {required bool isFavorite}) =>
      (update(queryHistory)..where(
        (t) => t.id.equals(id),
      )).write(QueryHistoryCompanion(isFavorite: Value(isFavorite)));
}
