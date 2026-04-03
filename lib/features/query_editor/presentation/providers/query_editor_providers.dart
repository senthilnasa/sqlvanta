import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../connections/presentation/providers/connection_providers.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';
import '../../data/datasources/query_history_datasource.dart';

part 'query_editor_providers.g.dart';

@riverpod
MysqlQueryExecutor queryExecutor(QueryExecutorRef ref) =>
    const MysqlQueryExecutor();

@riverpod
QueryHistoryDatasource queryHistoryDatasource(QueryHistoryDatasourceRef ref) =>
    QueryHistoryDatasource(ref.watch(appDatabaseProvider).queryHistoryDao);

// Per-tab SQL content
@riverpod
class EditorContent extends _$EditorContent {
  @override
  String build(String tabId) => '';

  void update(String sql) => state = sql;
}

// Per-tab execution state
@riverpod
class QueryExecution extends _$QueryExecution {
  @override
  AsyncValue<QueryResult?> build(String tabId) => const AsyncValue.data(null);

  Future<void> execute({
    required String sql,
    required String sessionId,
    String? database,
  }) async {
    state = const AsyncValue.loading();
    final sessions = ref.read(workspaceProvider);
    final session = sessions[sessionId];
    if (session == null) {
      state = AsyncValue.error('Session not found', StackTrace.current);
      return;
    }

    final executor = ref.read(queryExecutorProvider);
    final result = await executor.execute(
      session.mysqlConnection,
      sql,
      database: database,
    );

    // Save to history
    final ds = ref.read(queryHistoryDatasourceProvider);
    await ds.insert(
      connectionId: session.connection.id,
      databaseName: database,
      sqlText: sql,
      durationMs: result.duration.inMilliseconds,
      rowsAffected: result.affectedRows,
      hadError: result.isError,
      errorMessage: result.errorMessage,
    );

    state = AsyncValue.data(result);
  }
}
