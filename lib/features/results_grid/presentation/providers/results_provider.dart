import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../mysql/mysql_query_executor.dart';
import '../../../query_editor/presentation/providers/query_editor_providers.dart';

part 'results_provider.g.dart';

/// Watches the query execution state for a given tab and maps it to a
/// nullable [QueryResult]. Consumers show loading / error / data accordingly.
@riverpod
AsyncValue<QueryResult?> tabResults(TabResultsRef ref, String tabId) {
  return ref.watch(queryExecutionProvider(tabId));
}
