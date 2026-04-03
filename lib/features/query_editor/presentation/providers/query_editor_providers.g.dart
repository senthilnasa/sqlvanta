// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_editor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$queryExecutorHash() => r'65c1e863323c4c4d56ebdfeef5bafcc8900f3953';

/// See also [queryExecutor].
@ProviderFor(queryExecutor)
final queryExecutorProvider = AutoDisposeProvider<MysqlQueryExecutor>.internal(
  queryExecutor,
  name: r'queryExecutorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$queryExecutorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueryExecutorRef = AutoDisposeProviderRef<MysqlQueryExecutor>;
String _$queryHistoryDatasourceHash() =>
    r'd30ac2970ddacb1a9551937db0385b72eaa49a02';

/// See also [queryHistoryDatasource].
@ProviderFor(queryHistoryDatasource)
final queryHistoryDatasourceProvider =
    AutoDisposeProvider<QueryHistoryDatasource>.internal(
      queryHistoryDatasource,
      name: r'queryHistoryDatasourceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$queryHistoryDatasourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef QueryHistoryDatasourceRef =
    AutoDisposeProviderRef<QueryHistoryDatasource>;
String _$editorContentHash() => r'5380fb29e11e1a37e06cf078014876bc93e3f2b6';

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

abstract class _$EditorContent extends BuildlessAutoDisposeNotifier<String> {
  late final String tabId;

  String build(String tabId);
}

/// See also [EditorContent].
@ProviderFor(EditorContent)
const editorContentProvider = EditorContentFamily();

/// See also [EditorContent].
class EditorContentFamily extends Family<String> {
  /// See also [EditorContent].
  const EditorContentFamily();

  /// See also [EditorContent].
  EditorContentProvider call(String tabId) {
    return EditorContentProvider(tabId);
  }

  @override
  EditorContentProvider getProviderOverride(
    covariant EditorContentProvider provider,
  ) {
    return call(provider.tabId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'editorContentProvider';
}

/// See also [EditorContent].
class EditorContentProvider
    extends AutoDisposeNotifierProviderImpl<EditorContent, String> {
  /// See also [EditorContent].
  EditorContentProvider(String tabId)
    : this._internal(
        () => EditorContent()..tabId = tabId,
        from: editorContentProvider,
        name: r'editorContentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$editorContentHash,
        dependencies: EditorContentFamily._dependencies,
        allTransitiveDependencies:
            EditorContentFamily._allTransitiveDependencies,
        tabId: tabId,
      );

  EditorContentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tabId,
  }) : super.internal();

  final String tabId;

  @override
  String runNotifierBuild(covariant EditorContent notifier) {
    return notifier.build(tabId);
  }

  @override
  Override overrideWith(EditorContent Function() create) {
    return ProviderOverride(
      origin: this,
      override: EditorContentProvider._internal(
        () => create()..tabId = tabId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tabId: tabId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<EditorContent, String> createElement() {
    return _EditorContentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EditorContentProvider && other.tabId == tabId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tabId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EditorContentRef on AutoDisposeNotifierProviderRef<String> {
  /// The parameter `tabId` of this provider.
  String get tabId;
}

class _EditorContentProviderElement
    extends AutoDisposeNotifierProviderElement<EditorContent, String>
    with EditorContentRef {
  _EditorContentProviderElement(super.provider);

  @override
  String get tabId => (origin as EditorContentProvider).tabId;
}

String _$queryExecutionHash() => r'42880c6a2ea02826d4e68d975280e4702248217c';

abstract class _$QueryExecution
    extends BuildlessAutoDisposeNotifier<AsyncValue<QueryResult?>> {
  late final String tabId;

  AsyncValue<QueryResult?> build(String tabId);
}

/// See also [QueryExecution].
@ProviderFor(QueryExecution)
const queryExecutionProvider = QueryExecutionFamily();

/// See also [QueryExecution].
class QueryExecutionFamily extends Family<AsyncValue<QueryResult?>> {
  /// See also [QueryExecution].
  const QueryExecutionFamily();

  /// See also [QueryExecution].
  QueryExecutionProvider call(String tabId) {
    return QueryExecutionProvider(tabId);
  }

  @override
  QueryExecutionProvider getProviderOverride(
    covariant QueryExecutionProvider provider,
  ) {
    return call(provider.tabId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'queryExecutionProvider';
}

/// See also [QueryExecution].
class QueryExecutionProvider
    extends
        AutoDisposeNotifierProviderImpl<
          QueryExecution,
          AsyncValue<QueryResult?>
        > {
  /// See also [QueryExecution].
  QueryExecutionProvider(String tabId)
    : this._internal(
        () => QueryExecution()..tabId = tabId,
        from: queryExecutionProvider,
        name: r'queryExecutionProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$queryExecutionHash,
        dependencies: QueryExecutionFamily._dependencies,
        allTransitiveDependencies:
            QueryExecutionFamily._allTransitiveDependencies,
        tabId: tabId,
      );

  QueryExecutionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tabId,
  }) : super.internal();

  final String tabId;

  @override
  AsyncValue<QueryResult?> runNotifierBuild(covariant QueryExecution notifier) {
    return notifier.build(tabId);
  }

  @override
  Override overrideWith(QueryExecution Function() create) {
    return ProviderOverride(
      origin: this,
      override: QueryExecutionProvider._internal(
        () => create()..tabId = tabId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tabId: tabId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<QueryExecution, AsyncValue<QueryResult?>>
  createElement() {
    return _QueryExecutionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is QueryExecutionProvider && other.tabId == tabId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tabId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin QueryExecutionRef
    on AutoDisposeNotifierProviderRef<AsyncValue<QueryResult?>> {
  /// The parameter `tabId` of this provider.
  String get tabId;
}

class _QueryExecutionProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          QueryExecution,
          AsyncValue<QueryResult?>
        >
    with QueryExecutionRef {
  _QueryExecutionProviderElement(super.provider);

  @override
  String get tabId => (origin as QueryExecutionProvider).tabId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
