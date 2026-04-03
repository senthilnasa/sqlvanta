import '../features/connections/domain/entities/connection_entity.dart';
import 'mysql_client_factory.dart';

class MysqlConnectionTester {
  final MysqlClientFactory _factory;
  const MysqlConnectionTester(this._factory);

  /// Opens a connection, runs SELECT 1, closes it, and returns the round-trip
  /// duration. Throws on any connection or query error.
  Future<Duration> test(ConnectionEntity entity, String password) async {
    final conn = await _factory.create(entity, password);
    try {
      await conn.connect();
      final stopwatch = Stopwatch()..start();
      await conn.execute('SELECT 1');
      stopwatch.stop();
      return stopwatch.elapsed;
    } finally {
      await conn.close();
    }
  }
}
