// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_tree_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$schemaFetcherHash() => r'96325683ce29d1c0ece58e173ee29e19525f8472';

/// See also [schemaFetcher].
@ProviderFor(schemaFetcher)
final schemaFetcherProvider = AutoDisposeProvider<MysqlSchemaFetcher>.internal(
  schemaFetcher,
  name: r'schemaFetcherProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$schemaFetcherHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SchemaFetcherRef = AutoDisposeProviderRef<MysqlSchemaFetcher>;
String _$schemaDatabasesHash() => r'df09adb7b38a284481d86d407567966348e08281';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [schemaDatabases].
@ProviderFor(schemaDatabases)
const schemaDatabasesProvider = SchemaDatabasesFamily();

/// See also [schemaDatabases].
class SchemaDatabasesFamily extends Family<AsyncValue<List<DatabaseNode>>> {
  /// See also [schemaDatabases].
  const SchemaDatabasesFamily();

  /// See also [schemaDatabases].
  SchemaDatabasesProvider call(MySQLConnection conn) {
    return SchemaDatabasesProvider(conn);
  }

  @override
  SchemaDatabasesProvider getProviderOverride(
    covariant SchemaDatabasesProvider provider,
  ) {
    return call(provider.conn);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'schemaDatabasesProvider';
}

/// See also [schemaDatabases].
class SchemaDatabasesProvider
    extends AutoDisposeFutureProvider<List<DatabaseNode>> {
  /// See also [schemaDatabases].
  SchemaDatabasesProvider(MySQLConnection conn)
    : this._internal(
        (ref) => schemaDatabases(ref as SchemaDatabasesRef, conn),
        from: schemaDatabasesProvider,
        name: r'schemaDatabasesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$schemaDatabasesHash,
        dependencies: SchemaDatabasesFamily._dependencies,
        allTransitiveDependencies:
            SchemaDatabasesFamily._allTransitiveDependencies,
        conn: conn,
      );

  SchemaDatabasesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conn,
  }) : super.internal();

  final MySQLConnection conn;

  @override
  Override overrideWith(
    FutureOr<List<DatabaseNode>> Function(SchemaDatabasesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SchemaDatabasesProvider._internal(
        (ref) => create(ref as SchemaDatabasesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conn: conn,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<DatabaseNode>> createElement() {
    return _SchemaDatabasesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SchemaDatabasesProvider && other.conn == conn;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conn.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SchemaDatabasesRef on AutoDisposeFutureProviderRef<List<DatabaseNode>> {
  /// The parameter `conn` of this provider.
  MySQLConnection get conn;
}

class _SchemaDatabasesProviderElement
    extends AutoDisposeFutureProviderElement<List<DatabaseNode>>
    with SchemaDatabasesRef {
  _SchemaDatabasesProviderElement(super.provider);

  @override
  MySQLConnection get conn => (origin as SchemaDatabasesProvider).conn;
}

String _$schemaTablesHash() => r'3f17cb50b8c3c7f5a752a08231f5fa76861af711';

/// See also [schemaTables].
@ProviderFor(schemaTables)
const schemaTablesProvider = SchemaTablesFamily();

/// See also [schemaTables].
class SchemaTablesFamily extends Family<AsyncValue<List<TableNode>>> {
  /// See also [schemaTables].
  const SchemaTablesFamily();

  /// See also [schemaTables].
  SchemaTablesProvider call(MySQLConnection conn, String database) {
    return SchemaTablesProvider(conn, database);
  }

  @override
  SchemaTablesProvider getProviderOverride(
    covariant SchemaTablesProvider provider,
  ) {
    return call(provider.conn, provider.database);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'schemaTablesProvider';
}

/// See also [schemaTables].
class SchemaTablesProvider extends AutoDisposeFutureProvider<List<TableNode>> {
  /// See also [schemaTables].
  SchemaTablesProvider(MySQLConnection conn, String database)
    : this._internal(
        (ref) => schemaTables(ref as SchemaTablesRef, conn, database),
        from: schemaTablesProvider,
        name: r'schemaTablesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$schemaTablesHash,
        dependencies: SchemaTablesFamily._dependencies,
        allTransitiveDependencies:
            SchemaTablesFamily._allTransitiveDependencies,
        conn: conn,
        database: database,
      );

  SchemaTablesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conn,
    required this.database,
  }) : super.internal();

  final MySQLConnection conn;
  final String database;

  @override
  Override overrideWith(
    FutureOr<List<TableNode>> Function(SchemaTablesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SchemaTablesProvider._internal(
        (ref) => create(ref as SchemaTablesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conn: conn,
        database: database,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TableNode>> createElement() {
    return _SchemaTablesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SchemaTablesProvider &&
        other.conn == conn &&
        other.database == database;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conn.hashCode);
    hash = _SystemHash.combine(hash, database.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SchemaTablesRef on AutoDisposeFutureProviderRef<List<TableNode>> {
  /// The parameter `conn` of this provider.
  MySQLConnection get conn;

  /// The parameter `database` of this provider.
  String get database;
}

class _SchemaTablesProviderElement
    extends AutoDisposeFutureProviderElement<List<TableNode>>
    with SchemaTablesRef {
  _SchemaTablesProviderElement(super.provider);

  @override
  MySQLConnection get conn => (origin as SchemaTablesProvider).conn;
  @override
  String get database => (origin as SchemaTablesProvider).database;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
