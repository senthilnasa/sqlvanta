import 'package:mysql_client/mysql_client.dart';

class DatabaseInfo {
  final String name;
  const DatabaseInfo(this.name);
}

class TableInfo {
  final String name;
  final String type; // 'BASE TABLE' | 'VIEW'
  final int estimatedRows;
  bool get isView => type == 'VIEW';
  const TableInfo(this.name, this.type, this.estimatedRows);
}

class ColumnInfo {
  final String name;
  final String dataType;
  final bool isNullable;
  final String? columnDefault;
  final String? extra; // 'auto_increment', etc.
  final String? columnKey; // 'PRI', 'MUL', 'UNI'
  final String? columnType; // Full type e.g. 'varchar(255)', 'int(11)'
  const ColumnInfo(
      this.name, this.dataType, this.isNullable, this.columnDefault,
      this.extra, {this.columnKey, this.columnType});

  bool get isPrimaryKey => columnKey == 'PRI';
  bool get isForeignKey => columnKey == 'MUL';
  bool get isUniqueKey => columnKey == 'UNI';
}

class ConstraintInfo {
  final String constraintName;
  final String constraintType; // 'PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE'
  final String tableName;
  final List<String> columns;
  final String? refTable;
  final String? refColumn;
  const ConstraintInfo({
    required this.constraintName,
    required this.constraintType,
    required this.tableName,
    required this.columns,
    this.refTable,
    this.refColumn,
  });
}

class RoutineInfo {
  final String name;
  const RoutineInfo(this.name);
}

class TriggerInfo {
  final String name;
  const TriggerInfo(this.name);
}

class EventInfo {
  final String name;
  const EventInfo(this.name);
}

class ForeignKeyInfo {
  final String table;
  final String column;
  final String refTable;
  final String refColumn;
  /// The database that owns [refTable]. Empty string means same DB as [table].
  final String refDatabase;
  const ForeignKeyInfo({
    required this.table,
    required this.column,
    required this.refTable,
    required this.refColumn,
    this.refDatabase = '',
  });
}

class MysqlSchemaFetcher {
  const MysqlSchemaFetcher();

  Future<List<DatabaseInfo>> fetchDatabases(MySQLConnection conn) async {
    final result = await conn.execute(
      'SELECT SCHEMA_NAME FROM information_schema.SCHEMATA '
      "WHERE SCHEMA_NAME NOT IN ('information_schema','performance_schema','sys','mysql') "
      'ORDER BY SCHEMA_NAME',
    );
    return result.rows
        .map((r) => DatabaseInfo(r.colByName('SCHEMA_NAME') ?? ''))
        .where((d) => d.name.isNotEmpty)
        .toList();
  }

  Future<List<DatabaseInfo>> fetchAllDatabases(MySQLConnection conn) async {
    final result = await conn.execute(
      'SELECT SCHEMA_NAME FROM information_schema.SCHEMATA ORDER BY SCHEMA_NAME',
    );
    return result.rows
        .map((r) => DatabaseInfo(r.colByName('SCHEMA_NAME') ?? ''))
        .where((d) => d.name.isNotEmpty)
        .toList();
  }

  Future<List<TableInfo>> fetchTables(
      MySQLConnection conn, String database) async {
    final result = await conn.execute(
      'SELECT TABLE_NAME, TABLE_TYPE, COALESCE(TABLE_ROWS, 0) AS TABLE_ROWS '
      'FROM information_schema.TABLES '
      'WHERE TABLE_SCHEMA = :db '
      'ORDER BY TABLE_NAME',
      {'db': database},
    );
    return result.rows.map((r) {
      return TableInfo(
        r.colByName('TABLE_NAME') ?? '',
        r.colByName('TABLE_TYPE') ?? 'BASE TABLE',
        int.tryParse(r.colByName('TABLE_ROWS') ?? '0') ?? 0,
      );
    }).toList();
  }

  Future<List<RoutineInfo>> fetchRoutines(
      MySQLConnection conn, String database, String routineType) async {
    final result = await conn.execute(
      'SELECT ROUTINE_NAME FROM information_schema.ROUTINES '
      'WHERE ROUTINE_SCHEMA = :db AND ROUTINE_TYPE = :type '
      'ORDER BY ROUTINE_NAME',
      {'db': database, 'type': routineType},
    );
    return result.rows
        .map((r) => RoutineInfo(r.colByName('ROUTINE_NAME') ?? ''))
        .where((r) => r.name.isNotEmpty)
        .toList();
  }

  Future<List<TriggerInfo>> fetchTriggers(
      MySQLConnection conn, String database) async {
    final result = await conn.execute(
      'SELECT TRIGGER_NAME FROM information_schema.TRIGGERS '
      'WHERE TRIGGER_SCHEMA = :db ORDER BY TRIGGER_NAME',
      {'db': database},
    );
    return result.rows
        .map((r) => TriggerInfo(r.colByName('TRIGGER_NAME') ?? ''))
        .where((t) => t.name.isNotEmpty)
        .toList();
  }

  Future<List<EventInfo>> fetchEvents(
      MySQLConnection conn, String database) async {
    final result = await conn.execute(
      'SELECT EVENT_NAME FROM information_schema.EVENTS '
      'WHERE EVENT_SCHEMA = :db ORDER BY EVENT_NAME',
      {'db': database},
    );
    return result.rows
        .map((r) => EventInfo(r.colByName('EVENT_NAME') ?? ''))
        .where((e) => e.name.isNotEmpty)
        .toList();
  }

  Future<List<ForeignKeyInfo>> fetchForeignKeys(
      MySQLConnection conn, String database) async {
    final result = await conn.execute(
      'SELECT kcu.TABLE_NAME, kcu.COLUMN_NAME, '
      'kcu.REFERENCED_TABLE_NAME, kcu.REFERENCED_COLUMN_NAME, '
      'kcu.REFERENCED_TABLE_SCHEMA '
      'FROM information_schema.KEY_COLUMN_USAGE kcu '
      'WHERE kcu.TABLE_SCHEMA = :db '
      'AND kcu.REFERENCED_TABLE_NAME IS NOT NULL '
      'ORDER BY kcu.TABLE_NAME, kcu.COLUMN_NAME',
      {'db': database},
    );
    return result.rows
        .map((r) {
          final refDb = r.colByName('REFERENCED_TABLE_SCHEMA') ?? '';
          return ForeignKeyInfo(
            table: r.colByName('TABLE_NAME') ?? '',
            column: r.colByName('COLUMN_NAME') ?? '',
            refTable: r.colByName('REFERENCED_TABLE_NAME') ?? '',
            refColumn: r.colByName('REFERENCED_COLUMN_NAME') ?? '',
            refDatabase: refDb == database ? '' : refDb,
          );
        })
        .where((fk) => fk.table.isNotEmpty && fk.refTable.isNotEmpty)
        .toList();
  }

  Future<List<ColumnInfo>> fetchColumns(
      MySQLConnection conn, String database, String table) async {
    final result = await conn.execute(
      'SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA, '
      'COLUMN_KEY, COLUMN_TYPE '
      'FROM information_schema.COLUMNS '
      'WHERE TABLE_SCHEMA = :db AND TABLE_NAME = :tbl '
      'ORDER BY ORDINAL_POSITION',
      {'db': database, 'tbl': table},
    );
    return result.rows.map((r) {
      return ColumnInfo(
        r.colByName('COLUMN_NAME') ?? '',
        r.colByName('DATA_TYPE') ?? '',
        (r.colByName('IS_NULLABLE') ?? 'YES') == 'YES',
        r.colByName('COLUMN_DEFAULT'),
        r.colByName('EXTRA'),
        columnKey: r.colByName('COLUMN_KEY'),
        columnType: r.colByName('COLUMN_TYPE'),
      );
    }).toList();
  }

  /// Fetch constraints (PK, FK, UNIQUE) for a table.
  Future<List<ConstraintInfo>> fetchConstraints(
      MySQLConnection conn, String database, String table) async {
    final result = await conn.execute(
      'SELECT tc.CONSTRAINT_NAME, tc.CONSTRAINT_TYPE, '
      'kcu.COLUMN_NAME, kcu.REFERENCED_TABLE_NAME, kcu.REFERENCED_COLUMN_NAME '
      'FROM information_schema.TABLE_CONSTRAINTS tc '
      'JOIN information_schema.KEY_COLUMN_USAGE kcu '
      'ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME '
      'AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA '
      'AND tc.TABLE_NAME = kcu.TABLE_NAME '
      'WHERE tc.TABLE_SCHEMA = :db AND tc.TABLE_NAME = :tbl '
      'ORDER BY tc.CONSTRAINT_TYPE, tc.CONSTRAINT_NAME, kcu.ORDINAL_POSITION',
      {'db': database, 'tbl': table},
    );

    final Map<String, ConstraintInfo> grouped = {};
    for (final r in result.rows) {
      final name = r.colByName('CONSTRAINT_NAME') ?? '';
      final type = r.colByName('CONSTRAINT_TYPE') ?? '';
      final col = r.colByName('COLUMN_NAME') ?? '';
      final refTable = r.colByName('REFERENCED_TABLE_NAME');
      final refCol = r.colByName('REFERENCED_COLUMN_NAME');

      if (grouped.containsKey(name)) {
        grouped[name] = ConstraintInfo(
          constraintName: name,
          constraintType: type,
          tableName: table,
          columns: [...grouped[name]!.columns, col],
          refTable: refTable,
          refColumn: refCol,
        );
      } else {
        grouped[name] = ConstraintInfo(
          constraintName: name,
          constraintType: type,
          tableName: table,
          columns: [col],
          refTable: refTable,
          refColumn: refCol,
        );
      }
    }
    return grouped.values.toList();
  }

  /// Fetch the CREATE TABLE DDL statement.
  Future<String> fetchCreateTable(
      MySQLConnection conn, String database, String table) async {
    try {
      final result = await conn.execute(
        'SHOW CREATE TABLE `$database`.`$table`',
      );
      if (result.rows.isEmpty) return '-- No DDL available';
      final row = result.rows.first;
      return row.colByName('Create Table') ??
             row.colByName('Create View') ??
             '-- No DDL available';
    } catch (e) {
      return '-- Error fetching DDL: $e';
    }
  }

  /// Fetch tables that reference a given table (reverse FK lookup).
  Future<List<ForeignKeyInfo>> fetchReferencedBy(
      MySQLConnection conn, String database, String table) async {
    final result = await conn.execute(
      'SELECT kcu.TABLE_NAME, kcu.COLUMN_NAME, '
      'kcu.REFERENCED_TABLE_NAME, kcu.REFERENCED_COLUMN_NAME '
      'FROM information_schema.KEY_COLUMN_USAGE kcu '
      'WHERE kcu.TABLE_SCHEMA = :db '
      'AND kcu.REFERENCED_TABLE_NAME = :tbl '
      'ORDER BY kcu.TABLE_NAME, kcu.COLUMN_NAME',
      {'db': database, 'tbl': table},
    );
    return result.rows
        .map((r) => ForeignKeyInfo(
              table: r.colByName('TABLE_NAME') ?? '',
              column: r.colByName('COLUMN_NAME') ?? '',
              refTable: r.colByName('REFERENCED_TABLE_NAME') ?? '',
              refColumn: r.colByName('REFERENCED_COLUMN_NAME') ?? '',
            ))
        .where((fk) => fk.table.isNotEmpty)
        .toList();
  }
}
