import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../features/settings/presentation/providers/preferences_provider.dart';
import '../features/settings/presentation/providers/update_provider.dart';
import 'router.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';

class SQLvantaApp extends ConsumerStatefulWidget {
  const SQLvantaApp({super.key});

  @override
  ConsumerState<SQLvantaApp> createState() => _SQLvantaAppState();
}

class _SQLvantaAppState extends ConsumerState<SQLvantaApp> with WindowListener {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // ── WindowListener — save bounds whenever the window is moved or resized ──

  @override
  void onWindowResized() => _saveBounds();

  @override
  void onWindowMoved() => _saveBounds();

  Future<void> _saveBounds() async {
    try {
      final size = await windowManager.getSize();
      final pos = await windowManager.getPosition();
      await ref.read(preferencesProvider.notifier).saveWindowBounds(
        width: size.width,
        height: size.height,
        x: pos.dx,
        y: pos.dy,
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeMode =
        ref.watch(preferencesProvider).whenData((p) {
          return switch (p.themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
        }).valueOrNull ??
        ThemeMode.system;

    // Show a toast when update check completes and an update is found.
    ref.listen(updateInfoProvider, (prev, next) {
      next.whenData((info) {
        if (info != null && info.hasUpdate) {
          BotToast.showCustomNotification(
            toastBuilder:
                (cancel) => _UpdateToast(
                  version: info.latestVersion,
                  onDismiss: cancel,
                ),
            duration: const Duration(seconds: 8),
            align: Alignment.topRight,
          );
        }
      });
    });

    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: SplashScreen(
          onDone: () {
            setState(() => _splashDone = true);
            // Background update check after splash completes.
            ref.read(updateInfoProvider.notifier).check();
          },
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SQLvanta',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: BotToastInit(),
    );
  }
}

// ── Update toast notification ─────────────────────────────────────────────────

class _UpdateToast extends StatelessWidget {
  final String version;
  final VoidCallback onDismiss;

  const _UpdateToast({required this.version, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.new_releases_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            'v$version is available — check Settings',
            style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 14,
              color: cs.onPrimaryContainer.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}
