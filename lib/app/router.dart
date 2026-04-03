import 'package:bot_toast/bot_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/connections/presentation/screens/connection_manager_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/workspace/presentation/screens/main_shell.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/workspace',
    observers: [BotToastNavigatorObserver()],
    routes: [
      GoRoute(
        path: '/connections',
        builder: (context, state) => const ConnectionManagerScreen(),
      ),
      // Main IDE shell — shown once any session is open
      GoRoute(
        path: '/workspace',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
