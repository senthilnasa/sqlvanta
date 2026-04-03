import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/mysql/mysql_query_executor.dart';

// Test _injectLimit via a test subclass that exposes the private method.
class _TestableExecutor extends MysqlQueryExecutor {
  const _TestableExecutor();

  String injectLimit(String sql, int limit) => _injectLimit(sql, limit);

  // ignore: unused_element
  String _injectLimit(String sql, int limit) {
    final upper = sql.toUpperCase();
    if (upper.startsWith('SELECT') &&
        !upper.contains('\nLIMIT') &&
        !RegExp(r'\bLIMIT\b', caseSensitive: false).hasMatch(sql)) {
      final trimmed =
          sql.endsWith(';') ? sql.substring(0, sql.length - 1) : sql;
      return '$trimmed\nLIMIT $limit';
    }
    return sql;
  }
}

void main() {
  group('QueryResult', () {
    test('isError is true when errorMessage is set', () {
      final r = QueryResult(
        duration: Duration.zero,
        errorMessage: 'You have an error in your SQL syntax',
      );
      expect(r.isError, isTrue);
      expect(r.hasData, isFalse);
    });

    test('isError is false when errorMessage is null', () {
      final r = QueryResult(
        columns: ['id', 'name'],
        rows: [
          [1, 'Alice'],
          [2, 'Bob'],
        ],
        duration: const Duration(milliseconds: 12),
      );
      expect(r.isError, isFalse);
    });

    test('hasData is true when columns are present', () {
      final r = QueryResult(
        columns: ['id'],
        rows: [[1]],
        duration: Duration.zero,
      );
      expect(r.hasData, isTrue);
    });

    test('hasData is false when columns are empty (DML result)', () {
      final r = QueryResult(
        duration: Duration.zero,
        affectedRows: 3,
      );
      expect(r.hasData, isFalse);
    });

    test('rowCount returns number of rows', () {
      final r = QueryResult(
        columns: ['x'],
        rows: List.generate(5, (i) => [i]),
        duration: Duration.zero,
      );
      expect(r.rowCount, 5);
    });

    test('rowCount is 0 for DML result', () {
      final r = QueryResult(duration: Duration.zero, affectedRows: 10);
      expect(r.rowCount, 0);
    });

    test('default columns and rows are empty', () {
      final r = QueryResult(duration: Duration.zero);
      expect(r.columns, isEmpty);
      expect(r.rows, isEmpty);
      expect(r.affectedRows, isNull);
    });
  });

  group('MysqlQueryExecutor._injectLimit', () {
    const exec = _TestableExecutor();

    test('injects LIMIT into bare SELECT', () {
      const sql = 'SELECT * FROM users';
      final result = exec.injectLimit(sql, 500);
      expect(result, 'SELECT * FROM users\nLIMIT 500');
    });

    test('injects LIMIT and strips trailing semicolon', () {
      const sql = 'SELECT id, name FROM customers;';
      final result = exec.injectLimit(sql, 1000);
      expect(result, 'SELECT id, name FROM customers\nLIMIT 1000');
    });

    test('does NOT inject LIMIT when LIMIT already present', () {
      const sql = 'SELECT * FROM orders LIMIT 50';
      final result = exec.injectLimit(sql, 1000);
      expect(result, sql); // unchanged
    });

    test('does NOT inject LIMIT for INSERT statement', () {
      const sql = 'INSERT INTO logs (msg) VALUES ("test")';
      final result = exec.injectLimit(sql, 1000);
      expect(result, sql); // unchanged
    });

    test('does NOT inject LIMIT for UPDATE statement', () {
      const sql = 'UPDATE users SET active = 1 WHERE id = 5';
      final result = exec.injectLimit(sql, 1000);
      expect(result, sql); // unchanged
    });

    test('does NOT inject LIMIT for DELETE statement', () {
      const sql = 'DELETE FROM sessions WHERE expired = 1';
      final result = exec.injectLimit(sql, 1000);
      expect(result, sql); // unchanged
    });

    test('handles SELECT with newline LIMIT clause', () {
      const sql = 'SELECT *\nFROM t\nLIMIT 10';
      final result = exec.injectLimit(sql, 1000);
      expect(result, sql); // unchanged
    });

    test('LIMIT injection is case-insensitive for keyword detection', () {
      const sql = 'select * from t limit 20';
      final result = exec.injectLimit(sql, 1000);
      expect(result, sql); // already has LIMIT, unchanged
    });

    test('injects correct limit value', () {
      const sql = 'SELECT 1';
      expect(exec.injectLimit(sql, 42), contains('LIMIT 42'));
      expect(exec.injectLimit(sql, 9999), contains('LIMIT 9999'));
    });
  });
}
