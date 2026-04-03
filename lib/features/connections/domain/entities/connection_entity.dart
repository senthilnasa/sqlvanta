import 'package:equatable/equatable.dart';

class ConnectionEntity extends Equatable {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? defaultDatabase;
  final bool useSsl;
  final String? sslCaCertPath;
  final int connectionTimeout;
  final int sortOrder;
  final String? colorTag;
  final String? notes;
  final DateTime? lastConnectedAt;

  const ConnectionEntity({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.defaultDatabase,
    this.useSsl = false,
    this.sslCaCertPath,
    this.connectionTimeout = 30,
    this.sortOrder = 0,
    this.colorTag,
    this.notes,
    this.lastConnectedAt,
  });

  ConnectionEntity copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? defaultDatabase,
    bool? useSsl,
    String? sslCaCertPath,
    int? connectionTimeout,
    int? sortOrder,
    String? colorTag,
    String? notes,
    DateTime? lastConnectedAt,
  }) {
    return ConnectionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      defaultDatabase: defaultDatabase ?? this.defaultDatabase,
      useSsl: useSsl ?? this.useSsl,
      sslCaCertPath: sslCaCertPath ?? this.sslCaCertPath,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      sortOrder: sortOrder ?? this.sortOrder,
      colorTag: colorTag ?? this.colorTag,
      notes: notes ?? this.notes,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, host, port, username, defaultDatabase,
        useSsl, sslCaCertPath, connectionTimeout,
        sortOrder, colorTag, notes, lastConnectedAt,
      ];
}
