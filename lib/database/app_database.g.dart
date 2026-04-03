// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ConnectionsTable extends Connections
    with TableInfo<$ConnectionsTable, Connection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3306),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordKeyMeta = const VerificationMeta(
    'passwordKey',
  );
  @override
  late final GeneratedColumn<String> passwordKey = GeneratedColumn<String>(
    'password_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultDatabaseMeta = const VerificationMeta(
    'defaultDatabase',
  );
  @override
  late final GeneratedColumn<String> defaultDatabase = GeneratedColumn<String>(
    'default_database',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useSslMeta = const VerificationMeta('useSsl');
  @override
  late final GeneratedColumn<bool> useSsl = GeneratedColumn<bool>(
    'use_ssl',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_ssl" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sslCaCertPathMeta = const VerificationMeta(
    'sslCaCertPath',
  );
  @override
  late final GeneratedColumn<String> sslCaCertPath = GeneratedColumn<String>(
    'ssl_ca_cert_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _connectionTimeoutMeta = const VerificationMeta(
    'connectionTimeout',
  );
  @override
  late final GeneratedColumn<int> connectionTimeout = GeneratedColumn<int>(
    'connection_timeout',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastConnectedAtMeta = const VerificationMeta(
    'lastConnectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastConnectedAt =
      GeneratedColumn<DateTime>(
        'last_connected_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<String> colorTag = GeneratedColumn<String>(
    'color_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    host,
    port,
    username,
    passwordKey,
    defaultDatabase,
    useSsl,
    sslCaCertPath,
    connectionTimeout,
    createdAt,
    updatedAt,
    lastConnectedAt,
    sortOrder,
    colorTag,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Connection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_key')) {
      context.handle(
        _passwordKeyMeta,
        passwordKey.isAcceptableOrUnknown(
          data['password_key']!,
          _passwordKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordKeyMeta);
    }
    if (data.containsKey('default_database')) {
      context.handle(
        _defaultDatabaseMeta,
        defaultDatabase.isAcceptableOrUnknown(
          data['default_database']!,
          _defaultDatabaseMeta,
        ),
      );
    }
    if (data.containsKey('use_ssl')) {
      context.handle(
        _useSslMeta,
        useSsl.isAcceptableOrUnknown(data['use_ssl']!, _useSslMeta),
      );
    }
    if (data.containsKey('ssl_ca_cert_path')) {
      context.handle(
        _sslCaCertPathMeta,
        sslCaCertPath.isAcceptableOrUnknown(
          data['ssl_ca_cert_path']!,
          _sslCaCertPathMeta,
        ),
      );
    }
    if (data.containsKey('connection_timeout')) {
      context.handle(
        _connectionTimeoutMeta,
        connectionTimeout.isAcceptableOrUnknown(
          data['connection_timeout']!,
          _connectionTimeoutMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_connected_at')) {
      context.handle(
        _lastConnectedAtMeta,
        lastConnectedAt.isAcceptableOrUnknown(
          data['last_connected_at']!,
          _lastConnectedAtMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Connection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Connection(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      host:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}host'],
          )!,
      port:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}port'],
          )!,
      username:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}username'],
          )!,
      passwordKey:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}password_key'],
          )!,
      defaultDatabase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_database'],
      ),
      useSsl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}use_ssl'],
          )!,
      sslCaCertPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ssl_ca_cert_path'],
      ),
      connectionTimeout:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}connection_timeout'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
      lastConnectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_connected_at'],
      ),
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_tag'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $ConnectionsTable createAlias(String alias) {
    return $ConnectionsTable(attachedDatabase, alias);
  }
}

class Connection extends DataClass implements Insertable<Connection> {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String passwordKey;
  final String? defaultDatabase;
  final bool useSsl;
  final String? sslCaCertPath;
  final int connectionTimeout;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConnectedAt;
  final int sortOrder;
  final String? colorTag;
  final String? notes;
  const Connection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.passwordKey,
    this.defaultDatabase,
    required this.useSsl,
    this.sslCaCertPath,
    required this.connectionTimeout,
    required this.createdAt,
    required this.updatedAt,
    this.lastConnectedAt,
    required this.sortOrder,
    this.colorTag,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['username'] = Variable<String>(username);
    map['password_key'] = Variable<String>(passwordKey);
    if (!nullToAbsent || defaultDatabase != null) {
      map['default_database'] = Variable<String>(defaultDatabase);
    }
    map['use_ssl'] = Variable<bool>(useSsl);
    if (!nullToAbsent || sslCaCertPath != null) {
      map['ssl_ca_cert_path'] = Variable<String>(sslCaCertPath);
    }
    map['connection_timeout'] = Variable<int>(connectionTimeout);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastConnectedAt != null) {
      map['last_connected_at'] = Variable<DateTime>(lastConnectedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || colorTag != null) {
      map['color_tag'] = Variable<String>(colorTag);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ConnectionsCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      port: Value(port),
      username: Value(username),
      passwordKey: Value(passwordKey),
      defaultDatabase:
          defaultDatabase == null && nullToAbsent
              ? const Value.absent()
              : Value(defaultDatabase),
      useSsl: Value(useSsl),
      sslCaCertPath:
          sslCaCertPath == null && nullToAbsent
              ? const Value.absent()
              : Value(sslCaCertPath),
      connectionTimeout: Value(connectionTimeout),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastConnectedAt:
          lastConnectedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastConnectedAt),
      sortOrder: Value(sortOrder),
      colorTag:
          colorTag == null && nullToAbsent
              ? const Value.absent()
              : Value(colorTag),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Connection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Connection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      username: serializer.fromJson<String>(json['username']),
      passwordKey: serializer.fromJson<String>(json['passwordKey']),
      defaultDatabase: serializer.fromJson<String?>(json['defaultDatabase']),
      useSsl: serializer.fromJson<bool>(json['useSsl']),
      sslCaCertPath: serializer.fromJson<String?>(json['sslCaCertPath']),
      connectionTimeout: serializer.fromJson<int>(json['connectionTimeout']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastConnectedAt: serializer.fromJson<DateTime?>(json['lastConnectedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      colorTag: serializer.fromJson<String?>(json['colorTag']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'username': serializer.toJson<String>(username),
      'passwordKey': serializer.toJson<String>(passwordKey),
      'defaultDatabase': serializer.toJson<String?>(defaultDatabase),
      'useSsl': serializer.toJson<bool>(useSsl),
      'sslCaCertPath': serializer.toJson<String?>(sslCaCertPath),
      'connectionTimeout': serializer.toJson<int>(connectionTimeout),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastConnectedAt': serializer.toJson<DateTime?>(lastConnectedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'colorTag': serializer.toJson<String?>(colorTag),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Connection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? passwordKey,
    Value<String?> defaultDatabase = const Value.absent(),
    bool? useSsl,
    Value<String?> sslCaCertPath = const Value.absent(),
    int? connectionTimeout,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastConnectedAt = const Value.absent(),
    int? sortOrder,
    Value<String?> colorTag = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => Connection(
    id: id ?? this.id,
    name: name ?? this.name,
    host: host ?? this.host,
    port: port ?? this.port,
    username: username ?? this.username,
    passwordKey: passwordKey ?? this.passwordKey,
    defaultDatabase:
        defaultDatabase.present ? defaultDatabase.value : this.defaultDatabase,
    useSsl: useSsl ?? this.useSsl,
    sslCaCertPath:
        sslCaCertPath.present ? sslCaCertPath.value : this.sslCaCertPath,
    connectionTimeout: connectionTimeout ?? this.connectionTimeout,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastConnectedAt:
        lastConnectedAt.present ? lastConnectedAt.value : this.lastConnectedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    colorTag: colorTag.present ? colorTag.value : this.colorTag,
    notes: notes.present ? notes.value : this.notes,
  );
  Connection copyWithCompanion(ConnectionsCompanion data) {
    return Connection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      passwordKey:
          data.passwordKey.present ? data.passwordKey.value : this.passwordKey,
      defaultDatabase:
          data.defaultDatabase.present
              ? data.defaultDatabase.value
              : this.defaultDatabase,
      useSsl: data.useSsl.present ? data.useSsl.value : this.useSsl,
      sslCaCertPath:
          data.sslCaCertPath.present
              ? data.sslCaCertPath.value
              : this.sslCaCertPath,
      connectionTimeout:
          data.connectionTimeout.present
              ? data.connectionTimeout.value
              : this.connectionTimeout,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastConnectedAt:
          data.lastConnectedAt.present
              ? data.lastConnectedAt.value
              : this.lastConnectedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Connection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('passwordKey: $passwordKey, ')
          ..write('defaultDatabase: $defaultDatabase, ')
          ..write('useSsl: $useSsl, ')
          ..write('sslCaCertPath: $sslCaCertPath, ')
          ..write('connectionTimeout: $connectionTimeout, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('colorTag: $colorTag, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    host,
    port,
    username,
    passwordKey,
    defaultDatabase,
    useSsl,
    sslCaCertPath,
    connectionTimeout,
    createdAt,
    updatedAt,
    lastConnectedAt,
    sortOrder,
    colorTag,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Connection &&
          other.id == this.id &&
          other.name == this.name &&
          other.host == this.host &&
          other.port == this.port &&
          other.username == this.username &&
          other.passwordKey == this.passwordKey &&
          other.defaultDatabase == this.defaultDatabase &&
          other.useSsl == this.useSsl &&
          other.sslCaCertPath == this.sslCaCertPath &&
          other.connectionTimeout == this.connectionTimeout &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastConnectedAt == this.lastConnectedAt &&
          other.sortOrder == this.sortOrder &&
          other.colorTag == this.colorTag &&
          other.notes == this.notes);
}

class ConnectionsCompanion extends UpdateCompanion<Connection> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> host;
  final Value<int> port;
  final Value<String> username;
  final Value<String> passwordKey;
  final Value<String?> defaultDatabase;
  final Value<bool> useSsl;
  final Value<String?> sslCaCertPath;
  final Value<int> connectionTimeout;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastConnectedAt;
  final Value<int> sortOrder;
  final Value<String?> colorTag;
  final Value<String?> notes;
  final Value<int> rowid;
  const ConnectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordKey = const Value.absent(),
    this.defaultDatabase = const Value.absent(),
    this.useSsl = const Value.absent(),
    this.sslCaCertPath = const Value.absent(),
    this.connectionTimeout = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionsCompanion.insert({
    required String id,
    required String name,
    required String host,
    this.port = const Value.absent(),
    required String username,
    required String passwordKey,
    this.defaultDatabase = const Value.absent(),
    this.useSsl = const Value.absent(),
    this.sslCaCertPath = const Value.absent(),
    this.connectionTimeout = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       host = Value(host),
       username = Value(username),
       passwordKey = Value(passwordKey);
  static Insertable<Connection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? passwordKey,
    Expression<String>? defaultDatabase,
    Expression<bool>? useSsl,
    Expression<String>? sslCaCertPath,
    Expression<int>? connectionTimeout,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastConnectedAt,
    Expression<int>? sortOrder,
    Expression<String>? colorTag,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (passwordKey != null) 'password_key': passwordKey,
      if (defaultDatabase != null) 'default_database': defaultDatabase,
      if (useSsl != null) 'use_ssl': useSsl,
      if (sslCaCertPath != null) 'ssl_ca_cert_path': sslCaCertPath,
      if (connectionTimeout != null) 'connection_timeout': connectionTimeout,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastConnectedAt != null) 'last_connected_at': lastConnectedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (colorTag != null) 'color_tag': colorTag,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? host,
    Value<int>? port,
    Value<String>? username,
    Value<String>? passwordKey,
    Value<String?>? defaultDatabase,
    Value<bool>? useSsl,
    Value<String?>? sslCaCertPath,
    Value<int>? connectionTimeout,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastConnectedAt,
    Value<int>? sortOrder,
    Value<String?>? colorTag,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return ConnectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      passwordKey: passwordKey ?? this.passwordKey,
      defaultDatabase: defaultDatabase ?? this.defaultDatabase,
      useSsl: useSsl ?? this.useSsl,
      sslCaCertPath: sslCaCertPath ?? this.sslCaCertPath,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      colorTag: colorTag ?? this.colorTag,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordKey.present) {
      map['password_key'] = Variable<String>(passwordKey.value);
    }
    if (defaultDatabase.present) {
      map['default_database'] = Variable<String>(defaultDatabase.value);
    }
    if (useSsl.present) {
      map['use_ssl'] = Variable<bool>(useSsl.value);
    }
    if (sslCaCertPath.present) {
      map['ssl_ca_cert_path'] = Variable<String>(sslCaCertPath.value);
    }
    if (connectionTimeout.present) {
      map['connection_timeout'] = Variable<int>(connectionTimeout.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastConnectedAt.present) {
      map['last_connected_at'] = Variable<DateTime>(lastConnectedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<String>(colorTag.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('passwordKey: $passwordKey, ')
          ..write('defaultDatabase: $defaultDatabase, ')
          ..write('useSsl: $useSsl, ')
          ..write('sslCaCertPath: $sslCaCertPath, ')
          ..write('connectionTimeout: $connectionTimeout, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('colorTag: $colorTag, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueryHistoryTable extends QueryHistory
    with TableInfo<$QueryHistoryTable, QueryHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueryHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _databaseNameMeta = const VerificationMeta(
    'databaseName',
  );
  @override
  late final GeneratedColumn<String> databaseName = GeneratedColumn<String>(
    'database_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sqlTextMeta = const VerificationMeta(
    'sqlText',
  );
  @override
  late final GeneratedColumn<String> sqlText = GeneratedColumn<String>(
    'sql_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _executedAtMeta = const VerificationMeta(
    'executedAt',
  );
  @override
  late final GeneratedColumn<DateTime> executedAt = GeneratedColumn<DateTime>(
    'executed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowsAffectedMeta = const VerificationMeta(
    'rowsAffected',
  );
  @override
  late final GeneratedColumn<int> rowsAffected = GeneratedColumn<int>(
    'rows_affected',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hadErrorMeta = const VerificationMeta(
    'hadError',
  );
  @override
  late final GeneratedColumn<bool> hadError = GeneratedColumn<bool>(
    'had_error',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("had_error" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    connectionId,
    databaseName,
    sqlText,
    executedAt,
    durationMs,
    rowsAffected,
    hadError,
    errorMessage,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'query_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueryHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('database_name')) {
      context.handle(
        _databaseNameMeta,
        databaseName.isAcceptableOrUnknown(
          data['database_name']!,
          _databaseNameMeta,
        ),
      );
    }
    if (data.containsKey('sql_text')) {
      context.handle(
        _sqlTextMeta,
        sqlText.isAcceptableOrUnknown(data['sql_text']!, _sqlTextMeta),
      );
    } else if (isInserting) {
      context.missing(_sqlTextMeta);
    }
    if (data.containsKey('executed_at')) {
      context.handle(
        _executedAtMeta,
        executedAt.isAcceptableOrUnknown(data['executed_at']!, _executedAtMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('rows_affected')) {
      context.handle(
        _rowsAffectedMeta,
        rowsAffected.isAcceptableOrUnknown(
          data['rows_affected']!,
          _rowsAffectedMeta,
        ),
      );
    }
    if (data.containsKey('had_error')) {
      context.handle(
        _hadErrorMeta,
        hadError.isAcceptableOrUnknown(data['had_error']!, _hadErrorMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueryHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueryHistoryData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      connectionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}connection_id'],
          )!,
      databaseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}database_name'],
      ),
      sqlText:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sql_text'],
          )!,
      executedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}executed_at'],
          )!,
      durationMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}duration_ms'],
          )!,
      rowsAffected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rows_affected'],
      ),
      hadError:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}had_error'],
          )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      isFavorite:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_favorite'],
          )!,
    );
  }

  @override
  $QueryHistoryTable createAlias(String alias) {
    return $QueryHistoryTable(attachedDatabase, alias);
  }
}

class QueryHistoryData extends DataClass
    implements Insertable<QueryHistoryData> {
  final String id;
  final String connectionId;
  final String? databaseName;
  final String sqlText;
  final DateTime executedAt;
  final int durationMs;
  final int? rowsAffected;
  final bool hadError;
  final String? errorMessage;
  final bool isFavorite;
  const QueryHistoryData({
    required this.id,
    required this.connectionId,
    this.databaseName,
    required this.sqlText,
    required this.executedAt,
    required this.durationMs,
    this.rowsAffected,
    required this.hadError,
    this.errorMessage,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['connection_id'] = Variable<String>(connectionId);
    if (!nullToAbsent || databaseName != null) {
      map['database_name'] = Variable<String>(databaseName);
    }
    map['sql_text'] = Variable<String>(sqlText);
    map['executed_at'] = Variable<DateTime>(executedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || rowsAffected != null) {
      map['rows_affected'] = Variable<int>(rowsAffected);
    }
    map['had_error'] = Variable<bool>(hadError);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  QueryHistoryCompanion toCompanion(bool nullToAbsent) {
    return QueryHistoryCompanion(
      id: Value(id),
      connectionId: Value(connectionId),
      databaseName:
          databaseName == null && nullToAbsent
              ? const Value.absent()
              : Value(databaseName),
      sqlText: Value(sqlText),
      executedAt: Value(executedAt),
      durationMs: Value(durationMs),
      rowsAffected:
          rowsAffected == null && nullToAbsent
              ? const Value.absent()
              : Value(rowsAffected),
      hadError: Value(hadError),
      errorMessage:
          errorMessage == null && nullToAbsent
              ? const Value.absent()
              : Value(errorMessage),
      isFavorite: Value(isFavorite),
    );
  }

  factory QueryHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueryHistoryData(
      id: serializer.fromJson<String>(json['id']),
      connectionId: serializer.fromJson<String>(json['connectionId']),
      databaseName: serializer.fromJson<String?>(json['databaseName']),
      sqlText: serializer.fromJson<String>(json['sqlText']),
      executedAt: serializer.fromJson<DateTime>(json['executedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      rowsAffected: serializer.fromJson<int?>(json['rowsAffected']),
      hadError: serializer.fromJson<bool>(json['hadError']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'connectionId': serializer.toJson<String>(connectionId),
      'databaseName': serializer.toJson<String?>(databaseName),
      'sqlText': serializer.toJson<String>(sqlText),
      'executedAt': serializer.toJson<DateTime>(executedAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'rowsAffected': serializer.toJson<int?>(rowsAffected),
      'hadError': serializer.toJson<bool>(hadError),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  QueryHistoryData copyWith({
    String? id,
    String? connectionId,
    Value<String?> databaseName = const Value.absent(),
    String? sqlText,
    DateTime? executedAt,
    int? durationMs,
    Value<int?> rowsAffected = const Value.absent(),
    bool? hadError,
    Value<String?> errorMessage = const Value.absent(),
    bool? isFavorite,
  }) => QueryHistoryData(
    id: id ?? this.id,
    connectionId: connectionId ?? this.connectionId,
    databaseName: databaseName.present ? databaseName.value : this.databaseName,
    sqlText: sqlText ?? this.sqlText,
    executedAt: executedAt ?? this.executedAt,
    durationMs: durationMs ?? this.durationMs,
    rowsAffected: rowsAffected.present ? rowsAffected.value : this.rowsAffected,
    hadError: hadError ?? this.hadError,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  QueryHistoryData copyWithCompanion(QueryHistoryCompanion data) {
    return QueryHistoryData(
      id: data.id.present ? data.id.value : this.id,
      connectionId:
          data.connectionId.present
              ? data.connectionId.value
              : this.connectionId,
      databaseName:
          data.databaseName.present
              ? data.databaseName.value
              : this.databaseName,
      sqlText: data.sqlText.present ? data.sqlText.value : this.sqlText,
      executedAt:
          data.executedAt.present ? data.executedAt.value : this.executedAt,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      rowsAffected:
          data.rowsAffected.present
              ? data.rowsAffected.value
              : this.rowsAffected,
      hadError: data.hadError.present ? data.hadError.value : this.hadError,
      errorMessage:
          data.errorMessage.present
              ? data.errorMessage.value
              : this.errorMessage,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueryHistoryData(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('databaseName: $databaseName, ')
          ..write('sqlText: $sqlText, ')
          ..write('executedAt: $executedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowsAffected: $rowsAffected, ')
          ..write('hadError: $hadError, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    connectionId,
    databaseName,
    sqlText,
    executedAt,
    durationMs,
    rowsAffected,
    hadError,
    errorMessage,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueryHistoryData &&
          other.id == this.id &&
          other.connectionId == this.connectionId &&
          other.databaseName == this.databaseName &&
          other.sqlText == this.sqlText &&
          other.executedAt == this.executedAt &&
          other.durationMs == this.durationMs &&
          other.rowsAffected == this.rowsAffected &&
          other.hadError == this.hadError &&
          other.errorMessage == this.errorMessage &&
          other.isFavorite == this.isFavorite);
}

class QueryHistoryCompanion extends UpdateCompanion<QueryHistoryData> {
  final Value<String> id;
  final Value<String> connectionId;
  final Value<String?> databaseName;
  final Value<String> sqlText;
  final Value<DateTime> executedAt;
  final Value<int> durationMs;
  final Value<int?> rowsAffected;
  final Value<bool> hadError;
  final Value<String?> errorMessage;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const QueryHistoryCompanion({
    this.id = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.databaseName = const Value.absent(),
    this.sqlText = const Value.absent(),
    this.executedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowsAffected = const Value.absent(),
    this.hadError = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueryHistoryCompanion.insert({
    required String id,
    required String connectionId,
    this.databaseName = const Value.absent(),
    required String sqlText,
    this.executedAt = const Value.absent(),
    required int durationMs,
    this.rowsAffected = const Value.absent(),
    this.hadError = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       connectionId = Value(connectionId),
       sqlText = Value(sqlText),
       durationMs = Value(durationMs);
  static Insertable<QueryHistoryData> custom({
    Expression<String>? id,
    Expression<String>? connectionId,
    Expression<String>? databaseName,
    Expression<String>? sqlText,
    Expression<DateTime>? executedAt,
    Expression<int>? durationMs,
    Expression<int>? rowsAffected,
    Expression<bool>? hadError,
    Expression<String>? errorMessage,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionId != null) 'connection_id': connectionId,
      if (databaseName != null) 'database_name': databaseName,
      if (sqlText != null) 'sql_text': sqlText,
      if (executedAt != null) 'executed_at': executedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowsAffected != null) 'rows_affected': rowsAffected,
      if (hadError != null) 'had_error': hadError,
      if (errorMessage != null) 'error_message': errorMessage,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueryHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? connectionId,
    Value<String?>? databaseName,
    Value<String>? sqlText,
    Value<DateTime>? executedAt,
    Value<int>? durationMs,
    Value<int?>? rowsAffected,
    Value<bool>? hadError,
    Value<String?>? errorMessage,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return QueryHistoryCompanion(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      databaseName: databaseName ?? this.databaseName,
      sqlText: sqlText ?? this.sqlText,
      executedAt: executedAt ?? this.executedAt,
      durationMs: durationMs ?? this.durationMs,
      rowsAffected: rowsAffected ?? this.rowsAffected,
      hadError: hadError ?? this.hadError,
      errorMessage: errorMessage ?? this.errorMessage,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (databaseName.present) {
      map['database_name'] = Variable<String>(databaseName.value);
    }
    if (sqlText.present) {
      map['sql_text'] = Variable<String>(sqlText.value);
    }
    if (executedAt.present) {
      map['executed_at'] = Variable<DateTime>(executedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowsAffected.present) {
      map['rows_affected'] = Variable<int>(rowsAffected.value);
    }
    if (hadError.present) {
      map['had_error'] = Variable<bool>(hadError.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueryHistoryCompanion(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('databaseName: $databaseName, ')
          ..write('sqlText: $sqlText, ')
          ..write('executedAt: $executedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowsAffected: $rowsAffected, ')
          ..write('hadError: $hadError, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const Preference({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Preference copyWith({String? key, String? value, DateTime? updatedAt}) =>
      Preference(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConnectionsTable connections = $ConnectionsTable(this);
  late final $QueryHistoryTable queryHistory = $QueryHistoryTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final ConnectionsDao connectionsDao = ConnectionsDao(
    this as AppDatabase,
  );
  late final QueryHistoryDao queryHistoryDao = QueryHistoryDao(
    this as AppDatabase,
  );
  late final PreferencesDao preferencesDao = PreferencesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    connections,
    queryHistory,
    preferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('query_history', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ConnectionsTableCreateCompanionBuilder =
    ConnectionsCompanion Function({
      required String id,
      required String name,
      required String host,
      Value<int> port,
      required String username,
      required String passwordKey,
      Value<String?> defaultDatabase,
      Value<bool> useSsl,
      Value<String?> sslCaCertPath,
      Value<int> connectionTimeout,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastConnectedAt,
      Value<int> sortOrder,
      Value<String?> colorTag,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$ConnectionsTableUpdateCompanionBuilder =
    ConnectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> host,
      Value<int> port,
      Value<String> username,
      Value<String> passwordKey,
      Value<String?> defaultDatabase,
      Value<bool> useSsl,
      Value<String?> sslCaCertPath,
      Value<int> connectionTimeout,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastConnectedAt,
      Value<int> sortOrder,
      Value<String?> colorTag,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$ConnectionsTableReferences
    extends BaseReferences<_$AppDatabase, $ConnectionsTable, Connection> {
  $$ConnectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QueryHistoryTable, List<QueryHistoryData>>
  _queryHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.queryHistory,
    aliasName: $_aliasNameGenerator(
      db.connections.id,
      db.queryHistory.connectionId,
    ),
  );

  $$QueryHistoryTableProcessedTableManager get queryHistoryRefs {
    final manager = $$QueryHistoryTableTableManager(
      $_db,
      $_db.queryHistory,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_queryHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConnectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordKey => $composableBuilder(
    column: $table.passwordKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultDatabase => $composableBuilder(
    column: $table.defaultDatabase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useSsl => $composableBuilder(
    column: $table.useSsl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sslCaCertPath => $composableBuilder(
    column: $table.sslCaCertPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get connectionTimeout => $composableBuilder(
    column: $table.connectionTimeout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> queryHistoryRefs(
    Expression<bool> Function($$QueryHistoryTableFilterComposer f) f,
  ) {
    final $$QueryHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queryHistory,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueryHistoryTableFilterComposer(
            $db: $db,
            $table: $db.queryHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordKey => $composableBuilder(
    column: $table.passwordKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultDatabase => $composableBuilder(
    column: $table.defaultDatabase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useSsl => $composableBuilder(
    column: $table.useSsl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sslCaCertPath => $composableBuilder(
    column: $table.sslCaCertPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get connectionTimeout => $composableBuilder(
    column: $table.connectionTimeout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionsTable> {
  $$ConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordKey => $composableBuilder(
    column: $table.passwordKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultDatabase => $composableBuilder(
    column: $table.defaultDatabase,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useSsl =>
      $composableBuilder(column: $table.useSsl, builder: (column) => column);

  GeneratedColumn<String> get sslCaCertPath => $composableBuilder(
    column: $table.sslCaCertPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get connectionTimeout => $composableBuilder(
    column: $table.connectionTimeout,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> queryHistoryRefs<T extends Object>(
    Expression<T> Function($$QueryHistoryTableAnnotationComposer a) f,
  ) {
    final $$QueryHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queryHistory,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueryHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.queryHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionsTable,
          Connection,
          $$ConnectionsTableFilterComposer,
          $$ConnectionsTableOrderingComposer,
          $$ConnectionsTableAnnotationComposer,
          $$ConnectionsTableCreateCompanionBuilder,
          $$ConnectionsTableUpdateCompanionBuilder,
          (Connection, $$ConnectionsTableReferences),
          Connection,
          PrefetchHooks Function({bool queryHistoryRefs})
        > {
  $$ConnectionsTableTableManager(_$AppDatabase db, $ConnectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$ConnectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordKey = const Value.absent(),
                Value<String?> defaultDatabase = const Value.absent(),
                Value<bool> useSsl = const Value.absent(),
                Value<String?> sslCaCertPath = const Value.absent(),
                Value<int> connectionTimeout = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastConnectedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsCompanion(
                id: id,
                name: name,
                host: host,
                port: port,
                username: username,
                passwordKey: passwordKey,
                defaultDatabase: defaultDatabase,
                useSsl: useSsl,
                sslCaCertPath: sslCaCertPath,
                connectionTimeout: connectionTimeout,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastConnectedAt: lastConnectedAt,
                sortOrder: sortOrder,
                colorTag: colorTag,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String host,
                Value<int> port = const Value.absent(),
                required String username,
                required String passwordKey,
                Value<String?> defaultDatabase = const Value.absent(),
                Value<bool> useSsl = const Value.absent(),
                Value<String?> sslCaCertPath = const Value.absent(),
                Value<int> connectionTimeout = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastConnectedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsCompanion.insert(
                id: id,
                name: name,
                host: host,
                port: port,
                username: username,
                passwordKey: passwordKey,
                defaultDatabase: defaultDatabase,
                useSsl: useSsl,
                sslCaCertPath: sslCaCertPath,
                connectionTimeout: connectionTimeout,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastConnectedAt: lastConnectedAt,
                sortOrder: sortOrder,
                colorTag: colorTag,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ConnectionsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({queryHistoryRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (queryHistoryRefs) db.queryHistory],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (queryHistoryRefs)
                    await $_getPrefetchedData<
                      Connection,
                      $ConnectionsTable,
                      QueryHistoryData
                    >(
                      currentTable: table,
                      referencedTable: $$ConnectionsTableReferences
                          ._queryHistoryRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).queryHistoryRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.connectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionsTable,
      Connection,
      $$ConnectionsTableFilterComposer,
      $$ConnectionsTableOrderingComposer,
      $$ConnectionsTableAnnotationComposer,
      $$ConnectionsTableCreateCompanionBuilder,
      $$ConnectionsTableUpdateCompanionBuilder,
      (Connection, $$ConnectionsTableReferences),
      Connection,
      PrefetchHooks Function({bool queryHistoryRefs})
    >;
typedef $$QueryHistoryTableCreateCompanionBuilder =
    QueryHistoryCompanion Function({
      required String id,
      required String connectionId,
      Value<String?> databaseName,
      required String sqlText,
      Value<DateTime> executedAt,
      required int durationMs,
      Value<int?> rowsAffected,
      Value<bool> hadError,
      Value<String?> errorMessage,
      Value<bool> isFavorite,
      Value<int> rowid,
    });
typedef $$QueryHistoryTableUpdateCompanionBuilder =
    QueryHistoryCompanion Function({
      Value<String> id,
      Value<String> connectionId,
      Value<String?> databaseName,
      Value<String> sqlText,
      Value<DateTime> executedAt,
      Value<int> durationMs,
      Value<int?> rowsAffected,
      Value<bool> hadError,
      Value<String?> errorMessage,
      Value<bool> isFavorite,
      Value<int> rowid,
    });

final class $$QueryHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $QueryHistoryTable, QueryHistoryData> {
  $$QueryHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.connections.createAlias(
        $_aliasNameGenerator(db.queryHistory.connectionId, db.connections.id),
      );

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QueryHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $QueryHistoryTable> {
  $$QueryHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get databaseName => $composableBuilder(
    column: $table.databaseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sqlText => $composableBuilder(
    column: $table.sqlText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowsAffected => $composableBuilder(
    column: $table.rowsAffected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hadError => $composableBuilder(
    column: $table.hadError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueryHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $QueryHistoryTable> {
  $$QueryHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get databaseName => $composableBuilder(
    column: $table.databaseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sqlText => $composableBuilder(
    column: $table.sqlText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowsAffected => $composableBuilder(
    column: $table.rowsAffected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hadError => $composableBuilder(
    column: $table.hadError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueryHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueryHistoryTable> {
  $$QueryHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get databaseName => $composableBuilder(
    column: $table.databaseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sqlText =>
      $composableBuilder(column: $table.sqlText, builder: (column) => column);

  GeneratedColumn<DateTime> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowsAffected => $composableBuilder(
    column: $table.rowsAffected,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hadError =>
      $composableBuilder(column: $table.hadError, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueryHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueryHistoryTable,
          QueryHistoryData,
          $$QueryHistoryTableFilterComposer,
          $$QueryHistoryTableOrderingComposer,
          $$QueryHistoryTableAnnotationComposer,
          $$QueryHistoryTableCreateCompanionBuilder,
          $$QueryHistoryTableUpdateCompanionBuilder,
          (QueryHistoryData, $$QueryHistoryTableReferences),
          QueryHistoryData,
          PrefetchHooks Function({bool connectionId})
        > {
  $$QueryHistoryTableTableManager(_$AppDatabase db, $QueryHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$QueryHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$QueryHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$QueryHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> connectionId = const Value.absent(),
                Value<String?> databaseName = const Value.absent(),
                Value<String> sqlText = const Value.absent(),
                Value<DateTime> executedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> rowsAffected = const Value.absent(),
                Value<bool> hadError = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueryHistoryCompanion(
                id: id,
                connectionId: connectionId,
                databaseName: databaseName,
                sqlText: sqlText,
                executedAt: executedAt,
                durationMs: durationMs,
                rowsAffected: rowsAffected,
                hadError: hadError,
                errorMessage: errorMessage,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String connectionId,
                Value<String?> databaseName = const Value.absent(),
                required String sqlText,
                Value<DateTime> executedAt = const Value.absent(),
                required int durationMs,
                Value<int?> rowsAffected = const Value.absent(),
                Value<bool> hadError = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueryHistoryCompanion.insert(
                id: id,
                connectionId: connectionId,
                databaseName: databaseName,
                sqlText: sqlText,
                executedAt: executedAt,
                durationMs: durationMs,
                rowsAffected: rowsAffected,
                hadError: hadError,
                errorMessage: errorMessage,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$QueryHistoryTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (connectionId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.connectionId,
                            referencedTable: $$QueryHistoryTableReferences
                                ._connectionIdTable(db),
                            referencedColumn:
                                $$QueryHistoryTableReferences
                                    ._connectionIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QueryHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueryHistoryTable,
      QueryHistoryData,
      $$QueryHistoryTableFilterComposer,
      $$QueryHistoryTableOrderingComposer,
      $$QueryHistoryTableAnnotationComposer,
      $$QueryHistoryTableCreateCompanionBuilder,
      $$QueryHistoryTableUpdateCompanionBuilder,
      (QueryHistoryData, $$QueryHistoryTableReferences),
      QueryHistoryData,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConnectionsTableTableManager get connections =>
      $$ConnectionsTableTableManager(_db, _db.connections);
  $$QueryHistoryTableTableManager get queryHistory =>
      $$QueryHistoryTableTableManager(_db, _db.queryHistory);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
