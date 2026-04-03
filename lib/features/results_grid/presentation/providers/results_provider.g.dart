// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tabResultsHash() => r'8d041814638bc16ff6cefc1a1a3b4e886f811aa1';

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

/// Watches the query execution state for a given tab and maps it to a
/// nullable [QueryResult]. Consumers show loading / error / data accordingly.
///
/// Copied from [tabResults].
@ProviderFor(tabResults)
const tabResultsProvider = TabResultsFamily();

/// Watches the query execution state for a given tab and maps it to a
/// nullable [QueryResult]. Consumers show loading / error / data accordingly.
///
/// Copied from [tabResults].
class TabResultsFamily extends Family<AsyncValue<QueryResult?>> {
  /// Watches the query execution state for a given tab and maps it to a
  /// nullable [QueryResult]. Consumers show loading / error / data accordingly.
  ///
  /// Copied from [tabResults].
  const TabResultsFamily();

  /// Watches the query execution state for a given tab and maps it to a
  /// nullable [QueryResult]. Consumers show loading / error / data accordingly.
  ///
  /// Copied from [tabResults].
  TabResultsProvider call(String tabId) {
    return TabResultsProvider(tabId);
  }

  @override
  TabResultsProvider getProviderOverride(
    covariant TabResultsProvider provider,
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
  String? get name => r'tabResultsProvider';
}

/// Watches the query execution state for a given tab and maps it to a
/// nullable [QueryResult]. Consumers show loading / error / data accordingly.
///
/// Copied from [tabResults].
class TabResultsProvider extends AutoDisposeProvider<AsyncValue<QueryResult?>> {
  /// Watches the query execution state for a given tab and maps it to a
  /// nullable [QueryResult]. Consumers show loading / error / data accordingly.
  ///
  /// Copied from [tabResults].
  TabResultsProvider(String tabId)
    : this._internal(
        (ref) => tabResults(ref as TabResultsRef, tabId),
        from: tabResultsProvider,
        name: r'tabResultsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$tabResultsHash,
        dependencies: TabResultsFamily._dependencies,
        allTransitiveDependencies: TabResultsFamily._allTransitiveDependencies,
        tabId: tabId,
      );

  TabResultsProvider._internal(
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
  Override overrideWith(
    AsyncValue<QueryResult?> Function(TabResultsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TabResultsProvider._internal(
        (ref) => create(ref as TabResultsRef),
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
  AutoDisposeProviderElement<AsyncValue<QueryResult?>> createElement() {
    return _TabResultsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TabResultsProvider && other.tabId == tabId;
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
mixin TabResultsRef on AutoDisposeProviderRef<AsyncValue<QueryResult?>> {
  /// The parameter `tabId` of this provider.
  String get tabId;
}

class _TabResultsProviderElement
    extends AutoDisposeProviderElement<AsyncValue<QueryResult?>>
    with TabResultsRef {
  _TabResultsProviderElement(super.provider);

  @override
  String get tabId => (origin as TabResultsProvider).tabId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
