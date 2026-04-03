import 'package:mysql_client/mysql_client.dart';

import '../features/connections/domain/entities/connection_entity.dart';

class MysqlClientFactory {
  const MysqlClientFactory();

  Future<MySQLConnection> create(
    ConnectionEntity entity,
    String password,
  ) async {
    return MySQLConnection.createConnection(
      host: entity.host,
      port: entity.port,
      userName: entity.username,
      password: password,
      databaseName: entity.defaultDatabase,
      secure: entity.useSsl,
    );
  }
}
