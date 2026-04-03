import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../mysql/mysql_schema_fetcher.dart';

part 'schema_explorer_provider.g.dart';

/// Tracks which table is selected in the schema explorer.
@riverpod
class SelectedSchemaTable extends _$SelectedSchemaTable {
  @override
  ({String database, String table})? build() => null;

  void select(String database, String table) =>
      state = (database: database, table: table);

  void clear() => state = null;
}

/// Tracks favorites (in-memory).
@riverpod
class FavoriteTables extends _$FavoriteTables {
  @override
  Set<String> build() => {}; // Keys: 'db.table'

  void toggle(String db, String table) {
    final key = '$db.$table';
    if (state.contains(key)) {
      state = {...state}..remove(key);
    } else {
      state = {...state, key};
    }
  }

  bool isFavorite(String db, String table) => state.contains('$db.$table');
}

/// Tracks recently viewed tables (in-memory, last 20).
@riverpod
class RecentTables extends _$RecentTables {
  @override
  List<({String database, String table})> build() => [];

  void add(String database, String table) {
    final entry = (database: database, table: table);
    final updated = state.where(
      (e) => e.database != database || e.table != table,
    ).toList();
    updated.insert(0, entry);
    state = updated.take(20).toList();
  }
}

/// Schema explorer search query.
@riverpod
class SchemaSearchQuery extends _$SchemaSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Full table detail — columns, constraints, FK refs, DDL.
class TableDetail {
  final String database;
  final String tableName;
  final List<ColumnInfo> columns;
  final List<ConstraintInfo> constraints;
  final List<ForeignKeyInfo> foreignKeys;
  final List<ForeignKeyInfo> referencedBy;
  final String createTableDdl;

  const TableDetail({
    required this.database,
    required this.tableName,
    required this.columns,
    required this.constraints,
    required this.foreignKeys,
    required this.referencedBy,
    required this.createTableDdl,
  });

  List<ColumnInfo> get primaryKeyColumns =>
      columns.where((c) => c.isPrimaryKey).toList();

  List<ColumnInfo> get foreignKeyColumns =>
      columns.where((c) => c.isForeignKey).toList();

  List<ColumnInfo> get uniqueKeyColumns =>
      columns.where((c) => c.isUniqueKey).toList();
}
