import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/features/connections/domain/entities/connection_entity.dart';

void main() {
  const base = ConnectionEntity(
    id: 'abc-123',
    name: 'Local Dev',
    host: '127.0.0.1',
    port: 3306,
    username: 'root',
  );

  group('ConnectionEntity', () {
    test('has correct default values', () {
      expect(base.useSsl, isFalse);
      expect(base.connectionTimeout, 30);
      expect(base.sortOrder, 0);
      expect(base.defaultDatabase, isNull);
      expect(base.colorTag, isNull);
      expect(base.notes, isNull);
      expect(base.lastConnectedAt, isNull);
    });

    test('copyWith overrides specified fields', () {
      final updated = base.copyWith(name: 'Production', port: 3307);
      expect(updated.name, 'Production');
      expect(updated.port, 3307);
      // unchanged fields preserved
      expect(updated.id, 'abc-123');
      expect(updated.host, '127.0.0.1');
      expect(updated.username, 'root');
    });

    test('copyWith without args returns equivalent entity', () {
      final copy = base.copyWith();
      expect(copy, equals(base));
    });

    test('copyWith with useSsl toggles correctly', () {
      final withSsl = base.copyWith(useSsl: true);
      expect(withSsl.useSsl, isTrue);
    });

    test('equality — two entities with same fields are equal', () {
      const a = ConnectionEntity(
        id: 'x', name: 'A', host: 'localhost', port: 3306, username: 'root');
      const b = ConnectionEntity(
        id: 'x', name: 'A', host: 'localhost', port: 3306, username: 'root');
      expect(a, equals(b));
    });

    test('equality — different id makes them unequal', () {
      const a = ConnectionEntity(
        id: '1', name: 'A', host: 'localhost', port: 3306, username: 'root');
      const b = ConnectionEntity(
        id: '2', name: 'A', host: 'localhost', port: 3306, username: 'root');
      expect(a, isNot(equals(b)));
    });

    test('equality — different port makes them unequal', () {
      final a = base;
      final b = base.copyWith(port: 3307);
      expect(a, isNot(equals(b)));
    });
  });
}
