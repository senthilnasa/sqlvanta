import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'database/app_database.dart';
import 'features/connections/presentation/providers/connection_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Open the database once here so we can read saved window bounds
  // before the window is shown, and reuse the same instance in providers.
  final db = AppDatabase();
  final savedBounds = await _loadWindowBounds(db);

  final windowOptions = WindowOptions(
    size:
        savedBounds != null
            ? Size(savedBounds.$1, savedBounds.$2)
            : const Size(
              AppConstants.defaultWindowWidth,
              AppConstants.defaultWindowHeight,
            ),
    minimumSize: const Size(
      AppConstants.minWindowWidth,
      AppConstants.minWindowHeight,
    ),
    title: AppConstants.appName,
    // Only center on first launch (no saved position)
    center: savedBounds == null,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Restore saved position if we have one
    if (savedBounds != null) {
      await windowManager.setPosition(Offset(savedBounds.$3, savedBounds.$4));
    }
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ProviderScope(
      // Override appDatabaseProvider so the whole app reuses the
      // already-opened database instance (avoids opening it twice).
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const SQLvantaApp(),
    ),
  );
}

/// Returns (width, height, x, y) from saved prefs, or null on first launch.
Future<(double, double, double, double)?> _loadWindowBounds(
  AppDatabase db,
) async {
  try {
    final all = await db.preferencesDao.getAll();
    final map = {for (final p in all) p.key: p.value};
    final w = double.tryParse(map['window_width'] ?? '');
    final h = double.tryParse(map['window_height'] ?? '');
    final x = double.tryParse(map['window_x'] ?? '');
    final y = double.tryParse(map['window_y'] ?? '');
    if (w != null && h != null && x != null && y != null) {
      return (w, h, x, y);
    }
  } catch (_) {}
  return null;
}
