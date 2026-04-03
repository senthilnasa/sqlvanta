import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/preferences_table.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [Preferences])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.db);

  Future<Preference?> getByKey(String key) =>
      (select(preferences)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<List<Preference>> getAll() => select(preferences).get();

  Future<void> setValue(String key, String value) =>
      into(preferences).insertOnConflictUpdate(
        PreferencesCompanion.insert(
          key: key,
          value: value,
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> deleteByKey(String key) =>
      (delete(preferences)..where((t) => t.key.equals(key))).go();
}
