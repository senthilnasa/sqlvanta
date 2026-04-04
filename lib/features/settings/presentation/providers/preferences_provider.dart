import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../database/daos/preferences_dao.dart';
import '../../../connections/presentation/providers/connection_providers.dart';
import '../../domain/entities/app_preferences.dart';

part 'preferences_provider.g.dart';

@riverpod
PreferencesDao preferencesDao(PreferencesDaoRef ref) =>
    ref.watch(appDatabaseProvider).preferencesDao;

@riverpod
class Preferences extends _$Preferences {
  static const _keys = (
    themeMode: 'theme_mode',
    editorFontSize: 'editor_font_size',
    editorTabSize: 'editor_tab_size',
    editorWordWrap: 'editor_word_wrap',
    resultMaxRows: 'result_max_rows',
    nullDisplayText: 'null_display_text',
    sidebarWidth: 'sidebar_width',
    windowWidth: 'window_width',
    windowHeight: 'window_height',
    windowX: 'window_x',
    windowY: 'window_y',
  );

  @override
  Future<AppPreferences> build() async {
    final dao = ref.watch(preferencesDaoProvider);
    final all = await dao.getAll();
    final map = {for (final p in all) p.key: p.value};

    return AppPreferences(
      themeMode: map[_keys.themeMode] ?? 'system',
      editorFontSize: double.tryParse(map[_keys.editorFontSize] ?? '') ?? 14,
      editorTabSize: int.tryParse(map[_keys.editorTabSize] ?? '') ?? 2,
      editorWordWrap: map[_keys.editorWordWrap] == 'true',
      resultMaxRows: int.tryParse(map[_keys.resultMaxRows] ?? '') ?? 1000,
      nullDisplayText: map[_keys.nullDisplayText] ?? 'NULL',
      sidebarWidth: double.tryParse(map[_keys.sidebarWidth] ?? '') ?? 260,
      windowWidth: double.tryParse(map[_keys.windowWidth] ?? ''),
      windowHeight: double.tryParse(map[_keys.windowHeight] ?? ''),
      windowX: double.tryParse(map[_keys.windowX] ?? ''),
      windowY: double.tryParse(map[_keys.windowY] ?? ''),
    );
  }

  Future<void> save(AppPreferences prefs) async {
    final dao = ref.read(preferencesDaoProvider);
    final saves = [
      dao.setValue(_keys.themeMode, prefs.themeMode),
      dao.setValue(_keys.editorFontSize, prefs.editorFontSize.toString()),
      dao.setValue(_keys.editorTabSize, prefs.editorTabSize.toString()),
      dao.setValue(_keys.editorWordWrap, prefs.editorWordWrap.toString()),
      dao.setValue(_keys.resultMaxRows, prefs.resultMaxRows.toString()),
      dao.setValue(_keys.nullDisplayText, prefs.nullDisplayText),
      dao.setValue(_keys.sidebarWidth, prefs.sidebarWidth.toString()),
    ];
    if (prefs.windowWidth != null) {
      saves.add(dao.setValue(_keys.windowWidth, prefs.windowWidth.toString()));
    }
    if (prefs.windowHeight != null) {
      saves.add(
        dao.setValue(_keys.windowHeight, prefs.windowHeight.toString()),
      );
    }
    if (prefs.windowX != null) {
      saves.add(dao.setValue(_keys.windowX, prefs.windowX.toString()));
    }
    if (prefs.windowY != null) {
      saves.add(dao.setValue(_keys.windowY, prefs.windowY.toString()));
    }
    await Future.wait(saves);
    ref.invalidateSelf();
  }

  /// Saves only the window bounds without touching other preferences.
  Future<void> saveWindowBounds({
    required double width,
    required double height,
    required double x,
    required double y,
  }) async {
    final dao = ref.read(preferencesDaoProvider);
    await Future.wait([
      dao.setValue(_keys.windowWidth, width.toString()),
      dao.setValue(_keys.windowHeight, height.toString()),
      dao.setValue(_keys.windowX, x.toString()),
      dao.setValue(_keys.windowY, y.toString()),
    ]);
    // Don't invalidateSelf here — avoid re-building the whole UI on every resize
  }
}
