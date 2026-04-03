import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../database/app_database.dart';
import '../../domain/entities/connection_entity.dart';

extension ConnectionModelMapper on Connection {
  ConnectionEntity toEntity() => ConnectionEntity(
    id: id,
    name: name,
    host: host,
    port: port,
    username: username,
    defaultDatabase: defaultDatabase,
    useSsl: useSsl,
    sslCaCertPath: sslCaCertPath,
    connectionTimeout: connectionTimeout,
    sortOrder: sortOrder,
    colorTag: colorTag,
    notes: notes,
    lastConnectedAt: lastConnectedAt,
  );
}

extension ConnectionEntityMapper on ConnectionEntity {
  ConnectionsCompanion toCompanion() => ConnectionsCompanion(
    id: Value(id.isEmpty ? const Uuid().v4() : id),
    name: Value(name),
    host: Value(host),
    port: Value(port),
    username: Value(username),
    passwordKey: Value('${DbConstants.secureStorageKeyPrefix}$id'),
    defaultDatabase: Value(defaultDatabase),
    useSsl: Value(useSsl),
    sslCaCertPath: Value(sslCaCertPath),
    connectionTimeout: Value(connectionTimeout),
    sortOrder: Value(sortOrder),
    colorTag: Value(colorTag),
    notes: Value(notes),
    updatedAt: Value(DateTime.now()),
  );
}
