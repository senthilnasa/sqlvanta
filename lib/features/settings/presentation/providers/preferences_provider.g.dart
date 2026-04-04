// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preferencesDaoHash() => r'92c560d35dc2f11a2a6280b6b882e03397e6dd26';

/// See also [preferencesDao].
@ProviderFor(preferencesDao)
final preferencesDaoProvider = AutoDisposeProvider<PreferencesDao>.internal(
  preferencesDao,
  name: r'preferencesDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$preferencesDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PreferencesDaoRef = AutoDisposeProviderRef<PreferencesDao>;
String _$preferencesHash() => r'4bd0c93902d0e31426793b92fbae18346994567a';

/// See also [Preferences].
@ProviderFor(Preferences)
final preferencesProvider =
    AutoDisposeAsyncNotifierProvider<Preferences, AppPreferences>.internal(
      Preferences.new,
      name: r'preferencesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$preferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Preferences = AutoDisposeAsyncNotifier<AppPreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
