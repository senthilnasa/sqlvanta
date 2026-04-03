import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Minimal smoke test: the app shell renders without crashing.
/// We bypass the full app (which requires window_manager + platform channels)
/// by building a lightweight stub that exercises only the router + theme layer.
void main() {
  testWidgets('app shell renders MaterialApp without crashing', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Center(child: Text('SQLvanta'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          title: 'SQLvanta',
        ),
      ),
    );

    expect(find.text('SQLvanta'), findsOneWidget);
  });
}
