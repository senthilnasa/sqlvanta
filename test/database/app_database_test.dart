import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/database/app_database.dart';

/// Opens a pure in-memory database — no files, no platform channels.
AppDatabase _inMemoryDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _inMemoryDb());
  tearDown(() => db.close());

  // ── Connections ────────────────────────────────────────────────────────────

  group('ConnectionsDao', () {
    ConnectionsCompanion companion({
      String id = 'conn-1',
      String name = 'Local',
      String host = 'localhost',
      int port = 3306,
      String username = 'root',
      String passwordKey = 'sqlvanta_conn_conn-1',
    }) =>
        ConnectionsCompanion.insert(
          id: id,
          name: name,
          host: host,
          port: Value(port),
          username: username,
          passwordKey: passwordKey,
        );

    test('getAllConnections returns empty list initially', () async {
      final list = await db.connectionsDao.getAllConnections();
      expect(list, isEmpty);
    });

    test('upsertConnection inserts a new row', () async {
      await db.connectionsDao.upsertConnection(companion());
      final list = await db.connectionsDao.getAllConnections();
      expect(list.length, 1);
      expect(list.first.id, 'conn-1');
      expect(list.first.name, 'Local');
    });

    test('upsertConnection updates an existing row', () async {
      await db.connectionsDao.upsertConnection(companion());
      await db.connectionsDao.upsertConnection(
          companion(name: 'Renamed'));
      final list = await db.connectionsDao.getAllConnections();
      expect(list.length, 1);
      expect(list.first.name, 'Renamed');
    });

    test('getConnectionById returns correct row', () async {
      await db.connectionsDao.upsertConnection(companion());
      final conn = await db.connectionsDao.getConnectionById('conn-1');
      expect(conn, isNotNull);
      expect(conn!.host, 'localhost');
    });

    test('getConnectionById returns null for unknown id', () async {
      final conn =
          await db.connectionsDao.getConnectionById('missing');
      expect(conn, isNull);
    });

    test('deleteConnection removes the row', () async {
      await db.connectionsDao.upsertConnection(companion());
      await db.connectionsDao.deleteConnection('conn-1');
      final list = await db.connectionsDao.getAllConnections();
      expect(list, isEmpty);
    });

    test('getAllConnections respects sortOrder', () async {
      await db.connectionsDao
          .upsertConnection(companion(id: 'b', name: 'B').copyWith(sortOrder: const Value(2)));
      await db.connectionsDao
          .upsertConnection(companion(id: 'a', name: 'A').copyWith(sortOrder: const Value(1)));
      final list = await db.connectionsDao.getAllConnections();
      expect(list.map((c) => c.name).toList(), ['A', 'B']);
    });

    test('updateLastConnected sets lastConnectedAt', () async {
      await db.connectionsDao.upsertConnection(companion());
      await db.connectionsDao.updateLastConnected('conn-1');
      final conn =
          await db.connectionsDao.getConnectionById('conn-1');
      expect(conn!.lastConnectedAt, isNotNull);
    });

    test('watchAllConnections emits list on change', () async {
      final stream = db.connectionsDao.watchAllConnections();
      // Initial emit is empty
      final initial = await stream.first;
      expect(initial, isEmpty);

      await db.connectionsDao.upsertConnection(companion());
      // After insert, stream should emit updated list
      final updated = await stream.first;
      expect(updated.length, 1);
    });
  });

  // ── Query History ──────────────────────────────────────────────────────────

  group('QueryHistoryDao', () {
    Future<void> insertConn() => db.connectionsDao.upsertConnection(
          ConnectionsCompanion.insert(
            id: 'c1',
            name: 'X',
            host: 'h',
            port: const Value(3306),
            username: 'u',
            passwordKey: 'k',
          ),
        );

    QueryHistoryCompanion historyEntry({
      String id = 'h-1',
      String sql = 'SELECT 1',
      int durationMs = 10,
      bool hadError = false,
      DateTime? executedAt,
    }) =>
        QueryHistoryCompanion(
          id: Value(id),
          connectionId: const Value('c1'),
          sqlText: Value(sql),
          durationMs: Value(durationMs),
          hadError: Value(hadError),
          executedAt: executedAt != null
              ? Value(executedAt)
              : Value(DateTime.now()),
        );

    test('getRecentHistory returns empty initially', () async {
      await insertConn();
      final list = await db.queryHistoryDao
          .getRecentHistory(connectionId: 'c1');
      expect(list, isEmpty);
    });

    test('insertEntry adds a row', () async {
      await insertConn();
      await db.queryHistoryDao.insertEntry(historyEntry());
      final list = await db.queryHistoryDao
          .getRecentHistory(connectionId: 'c1');
      expect(list.length, 1);
      expect(list.first.sqlText, 'SELECT 1');
    });

    test('getRecentHistory respects limit', () async {
      await insertConn();
      for (var i = 0; i < 5; i++) {
        await db.queryHistoryDao.insertEntry(
            historyEntry(id: 'h-$i', sql: 'SELECT $i'));
      }
      final list = await db.queryHistoryDao
          .getRecentHistory(connectionId: 'c1', limit: 3);
      expect(list.length, 3);
    });

    test('getRecentHistory orders by executedAt descending', () async {
      await insertConn();
      final t1 = DateTime(2024, 1, 1, 12, 0, 0);
      final t2 = DateTime(2024, 1, 1, 12, 0, 1);
      await db.queryHistoryDao.insertEntry(
          historyEntry(id: 'h-1', sql: 'SELECT 1', executedAt: t1));
      await db.queryHistoryDao.insertEntry(
          historyEntry(id: 'h-2', sql: 'SELECT 2', executedAt: t2));
      final list = await db.queryHistoryDao
          .getRecentHistory(connectionId: 'c1');
      // Most recent first
      expect(list.first.sqlText, 'SELECT 2');
    });

    test('toggleFavorite sets isFavorite', () async {
      await insertConn();
      await db.queryHistoryDao.insertEntry(historyEntry());
      await db.queryHistoryDao
          .toggleFavorite('h-1', isFavorite: true);
      final list = await db.queryHistoryDao
          .getRecentHistory(connectionId: 'c1');
      expect(list.first.isFavorite, isTrue);
    });

    test('deleteForConnection removes all entries', () async {
      await insertConn();
      await db.queryHistoryDao.insertEntry(historyEntry(id: 'h-1'));
      await db.queryHistoryDao.insertEntry(historyEntry(id: 'h-2'));
      await db.queryHistoryDao.deleteForConnection('c1');
      final list = await db.queryHistoryDao
          .getRecentHistory(connectionId: 'c1');
      expect(list, isEmpty);
    });
  });

  // ── Preferences ───────────────────────────────────────────────────────────

  group('PreferencesDao', () {
    test('getByKey returns null when key does not exist', () async {
      final p = await db.preferencesDao.getByKey('theme_mode');
      expect(p, isNull);
    });

    test('setValue inserts a new preference', () async {
      await db.preferencesDao.setValue('theme_mode', 'dark');
      final p = await db.preferencesDao.getByKey('theme_mode');
      expect(p, isNotNull);
      expect(p!.value, 'dark');
    });

    test('setValue updates an existing preference', () async {
      await db.preferencesDao.setValue('theme_mode', 'light');
      await db.preferencesDao.setValue('theme_mode', 'dark');
      final p = await db.preferencesDao.getByKey('theme_mode');
      expect(p!.value, 'dark');
    });

    test('getAll returns all stored preferences', () async {
      await db.preferencesDao.setValue('theme_mode', 'dark');
      await db.preferencesDao.setValue('editor_font_size', '16');
      final all = await db.preferencesDao.getAll();
      expect(all.length, 2);
    });

    test('deleteByKey removes the preference', () async {
      await db.preferencesDao.setValue('theme_mode', 'dark');
      await db.preferencesDao.deleteByKey('theme_mode');
      final p = await db.preferencesDao.getByKey('theme_mode');
      expect(p, isNull);
    });
  });
}
