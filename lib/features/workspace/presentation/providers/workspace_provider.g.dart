// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSessionIdHash() => r'124eb060ae65b9f1650c76df48f96be89f66563a';

/// Tracks which server tab is currently active in the IDE shell.
///
/// Copied from [ActiveSessionId].
@ProviderFor(ActiveSessionId)
final activeSessionIdProvider =
    AutoDisposeNotifierProvider<ActiveSessionId, String?>.internal(
      ActiveSessionId.new,
      name: r'activeSessionIdProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$activeSessionIdHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveSessionId = AutoDisposeNotifier<String?>;
String _$workspaceHash() => r'6b411f62dfbb140c3425261d8b3ad697040b28b3';

/// See also [Workspace].
@ProviderFor(Workspace)
final workspaceProvider = AutoDisposeNotifierProvider<
  Workspace,
  Map<String, WorkspaceSession>
>.internal(
  Workspace.new,
  name: r'workspaceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$workspaceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Workspace = AutoDisposeNotifier<Map<String, WorkspaceSession>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
