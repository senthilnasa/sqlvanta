// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_explorer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedSchemaTableHash() =>
    r'9b69ad080cfd89fa67df1968d3286feac22b495e';

/// Tracks which table is selected in the schema explorer.
///
/// Copied from [SelectedSchemaTable].
@ProviderFor(SelectedSchemaTable)
final selectedSchemaTableProvider = AutoDisposeNotifierProvider<
  SelectedSchemaTable,
  ({String database, String table})?
>.internal(
  SelectedSchemaTable.new,
  name: r'selectedSchemaTableProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedSchemaTableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedSchemaTable =
    AutoDisposeNotifier<({String database, String table})?>;
String _$favoriteTablesHash() => r'ce91b249aa1168a9cb5c9587d2c15d2fa315c53f';

/// Tracks favorites (in-memory).
///
/// Copied from [FavoriteTables].
@ProviderFor(FavoriteTables)
final favoriteTablesProvider =
    AutoDisposeNotifierProvider<FavoriteTables, Set<String>>.internal(
      FavoriteTables.new,
      name: r'favoriteTablesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$favoriteTablesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteTables = AutoDisposeNotifier<Set<String>>;
String _$recentTablesHash() => r'87d0565402472c969e42aea23c7a37dc5001b8b3';

/// Tracks recently viewed tables (in-memory, last 20).
///
/// Copied from [RecentTables].
@ProviderFor(RecentTables)
final recentTablesProvider = AutoDisposeNotifierProvider<
  RecentTables,
  List<({String database, String table})>
>.internal(
  RecentTables.new,
  name: r'recentTablesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$recentTablesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RecentTables =
    AutoDisposeNotifier<List<({String database, String table})>>;
String _$schemaSearchQueryHash() => r'a04733991dd6977523ed9f047e580546f3d619d6';

/// Schema explorer search query.
///
/// Copied from [SchemaSearchQuery].
@ProviderFor(SchemaSearchQuery)
final schemaSearchQueryProvider =
    AutoDisposeNotifierProvider<SchemaSearchQuery, String>.internal(
      SchemaSearchQuery.new,
      name: r'schemaSearchQueryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$schemaSearchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SchemaSearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
