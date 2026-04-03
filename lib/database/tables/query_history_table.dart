import 'package:drift/drift.dart';

import 'connections_table.dart';

class QueryHistory extends Table {
  TextColumn get id => text()();
  TextColumn get connectionId =>
      text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get databaseName => text().nullable()();
  TextColumn get sqlText => text()();
  DateTimeColumn get executedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get durationMs => integer()();
  IntColumn get rowsAffected => integer().nullable()();
  BoolColumn get hadError => boolean().withDefault(const Constant(false))();
  TextColumn get errorMessage => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
