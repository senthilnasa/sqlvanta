import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlvanta/features/connections/domain/entities/connection_entity.dart';
import 'package:sqlvanta/features/connections/presentation/widgets/connection_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ConnectionForm — validation', () {
    testWidgets('shows error when name is empty on save', (tester) async {
      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (_, _) {},
          onTest: (_, _) {},
        ),
      ));

      // Clear the default name field content and tap Save
      final nameField = find.widgetWithText(TextFormField, 'Connection Name');
      await tester.tap(nameField);
      await tester.pump();

      // Tap Save without filling name
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows error when host is empty on save', (tester) async {
      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (_, _) {},
          onTest: (_, _) {},
        ),
      ));

      // Fill name, clear host
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Connection Name'), 'My DB');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Host'), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Host is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid port', (tester) async {
      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (_, _) {},
          onTest: (_, _) {},
        ),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Connection Name'), 'My DB');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Port'), '99999');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Invalid port'), findsOneWidget);
    });

    testWidgets('shows error when username is empty on save', (tester) async {
      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (_, _) {},
          onTest: (_, _) {},
        ),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Connection Name'), 'My DB');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('calls onSave with correct entity when form is valid',
        (tester) async {
      ConnectionEntity? savedEntity;
      String? savedPassword;

      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (e, p) {
            savedEntity = e;
            savedPassword = p;
          },
          onTest: (_, _) {},
        ),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Connection Name'), 'Prod DB');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Host'), '10.0.0.1');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Port'), '3306');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'admin');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'pass123');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(savedEntity, isNotNull);
      expect(savedEntity!.name, 'Prod DB');
      expect(savedEntity!.host, '10.0.0.1');
      expect(savedEntity!.port, 3306);
      expect(savedEntity!.username, 'admin');
      expect(savedPassword, 'pass123');
    });

    testWidgets('calls onTest when Test Connection is tapped with valid form',
        (tester) async {
      ConnectionEntity? testedEntity;

      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (_, _) {},
          onTest: (e, _) => testedEntity = e,
        ),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Connection Name'), 'Dev');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Host'), 'localhost');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Port'), '3306');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'root');

      await tester.tap(
          find.widgetWithText(OutlinedButton, 'Test Connection'));
      await tester.pump();

      expect(testedEntity, isNotNull);
      expect(testedEntity!.host, 'localhost');
    });

    testWidgets('pre-fills form when initial entity is provided',
        (tester) async {
      const entity = ConnectionEntity(
        id: 'id-1',
        name: 'Staging',
        host: '192.168.1.1',
        port: 3307,
        username: 'dev',
        defaultDatabase: 'mydb',
      );

      await tester.pumpWidget(_wrap(
        ConnectionForm(
          initial: entity,
          onSave: (_, _) {},
          onTest: (_, _) {},
        ),
      ));

      expect(find.widgetWithText(TextFormField, 'Connection Name'),
          findsOneWidget);
      // verify pre-filled values are visible
      expect(find.text('Staging'), findsOneWidget);
      expect(find.text('192.168.1.1'), findsOneWidget);
      expect(find.text('3307'), findsOneWidget);
      expect(find.text('dev'), findsOneWidget);
    });

    testWidgets('password field toggles visibility', (tester) async {
      await tester.pumpWidget(_wrap(
        ConnectionForm(
          onSave: (_, _) {},
          onTest: (_, _) {},
        ),
      ));

      // Find the visibility toggle icon
      final toggleIcon = find.byIcon(Icons.visibility_off);
      expect(toggleIcon, findsOneWidget);

      await tester.tap(toggleIcon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
