import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../query_editor/presentation/providers/query_editor_providers.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';

/// Per-tab EXPLAIN execution state.
/// Uses StateNotifier (no code-gen needed — keep it out of the .g.dart pipeline).
class ExplainNotifier extends StateNotifier<AsyncValue<QueryResult?>> {
  final Ref _ref;
  ExplainNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> execute({
    required String sql,
    required String sessionId,
    String? database,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = _ref.read(workspaceProvider)[sessionId];
      if (session == null) {
        state = AsyncValue.error('Session not found', StackTrace.current);
        return;
      }
      final trimmed = sql.trim();
      // Don't double-wrap if user already typed EXPLAIN
      final explainSql =
          trimmed.toUpperCase().startsWith('EXPLAIN')
              ? trimmed
              : 'EXPLAIN $trimmed';

      final result = await _ref
          .read(queryExecutorProvider)
          .execute(session.mysqlConnection, explainSql, database: database);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

final explainExecutionProvider = StateNotifierProvider.family
    .autoDispose<ExplainNotifier, AsyncValue<QueryResult?>, String>(
      (ref, tabId) => ExplainNotifier(ref),
    );
