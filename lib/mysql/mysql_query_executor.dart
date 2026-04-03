import 'package:mysql_client/mysql_client.dart';

import '../core/constants/db_constants.dart';

class QueryResult {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final int? affectedRows;
  final Duration duration;
  final String? errorMessage;

  const QueryResult({
    this.columns = const [],
    this.rows = const [],
    this.affectedRows,
    required this.duration,
    this.errorMessage,
  });

  bool get isError => errorMessage != null;
  bool get hasData => columns.isNotEmpty;
  int get rowCount => rows.length;
}

class MysqlQueryExecutor {
  final int maxRows;

  const MysqlQueryExecutor({
    this.maxRows = DbConstants.defaultResultMaxRows,
  });

  Future<QueryResult> execute(
    MySQLConnection conn,
    String sql, {
    String? database,
    int? rowLimit,
  }) async {
    final effectiveLimit = rowLimit ?? maxRows;
    final finalSql = _injectLimit(sql.trim(), effectiveLimit);

    if (database != null) {
      await conn.execute('USE `$database`');
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await conn.execute(finalSql);
      stopwatch.stop();

      final cols =
          result.cols.map((c) => c.name).toList();

      if (cols.isEmpty) {
        // DML result (INSERT/UPDATE/DELETE)
        return QueryResult(
          duration: stopwatch.elapsed,
          affectedRows: result.affectedRows.toInt(),
        );
      }

      // SELECT result
      final rows = result.rows.map((row) {
        return List<dynamic>.generate(
            cols.length, (i) => row.colAt(i));
      }).toList();

      return QueryResult(
        columns: cols,
        rows: rows,
        duration: stopwatch.elapsed,
        affectedRows: result.affectedRows.toInt(),
      );
    } catch (e) {
      stopwatch.stop();
      return QueryResult(
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Injects LIMIT into a bare SELECT that doesn't already have one.
  String _injectLimit(String sql, int limit) {
    final upper = sql.toUpperCase();
    // Only inject for SELECT statements without an existing LIMIT
    if (upper.startsWith('SELECT') && !upper.contains('\nLIMIT') &&
        !RegExp(r'\bLIMIT\b', caseSensitive: false).hasMatch(sql)) {
      // Strip trailing semicolon if present
      final trimmed =
          sql.endsWith(';') ? sql.substring(0, sql.length - 1) : sql;
      return '$trimmed\nLIMIT $limit';
    }
    return sql;
  }
}
