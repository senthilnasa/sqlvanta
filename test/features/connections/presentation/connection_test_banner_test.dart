import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/features/connections/presentation/widgets/connection_test_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ConnectionTestBanner', () {
    testWidgets('renders nothing when success is null', (tester) async {
      await tester.pumpWidget(_wrap(const ConnectionTestBanner()));
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
          _wrap(const ConnectionTestBanner(isLoading: true)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Testing connection…'), findsOneWidget);
    });

    testWidgets('shows success icon and latency message on success',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ConnectionTestBanner(
          success: true,
          latency: Duration(milliseconds: 35),
        ),
      ));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('35ms'), findsOneWidget);
      expect(find.textContaining('successful'), findsOneWidget);
    });

    testWidgets('shows error icon and message on failure', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConnectionTestBanner(
          success: false,
          errorMessage: 'Connection refused (port 3306)',
        ),
      ));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Connection refused (port 3306)'), findsOneWidget);
    });

    testWidgets('shows default failure text when no errorMessage', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConnectionTestBanner(success: false),
      ));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('loading state hides success/error content', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConnectionTestBanner(
          isLoading: true,
          success: true, // ignored while loading
          latency: Duration(milliseconds: 10),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });
  });
}
