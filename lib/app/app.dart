import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/providers/preferences_provider.dart';
import 'router.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';

class SQLvantaApp extends ConsumerStatefulWidget {
  const SQLvantaApp({super.key});

  @override
  ConsumerState<SQLvantaApp> createState() => _SQLvantaAppState();
}

class _SQLvantaAppState extends ConsumerState<SQLvantaApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(preferencesProvider).whenData((p) {
      return switch (p.themeMode) {
        'light' => ThemeMode.light,
        'dark'  => ThemeMode.dark,
        _       => ThemeMode.system,
      };
    }).valueOrNull ?? ThemeMode.system;

    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: SplashScreen(onDone: () => setState(() => _splashDone = true)),
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
