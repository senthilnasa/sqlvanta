import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/connections_dao.dart';
import 'daos/preferences_dao.dart';
import 'daos/query_history_dao.dart';
import 'tables/connections_table.dart';
import 'tables/preferences_table.dart';
import 'tables/query_history_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Connections, QueryHistory, Preferences],
  daos: [ConnectionsDao, QueryHistoryDao, PreferencesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing — accepts a custom executor
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Future migrations go here
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'sqlvanta', 'app.db'));
    await file.parent.create(recursive: true);
    return NativeDatabase.createInBackground(file);
  });
}
