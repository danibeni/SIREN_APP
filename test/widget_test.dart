// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siren_app/core/di/injection.dart';

import 'package:siren_app/main.dart';

void main() {
  testWidgets('SIREN app initializes correctly', (WidgetTester tester) async {
    // Initialize dependencies before building the app
    WidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const SirenApp());

    // Verify that the app initializes and shows the initialization screen
    expect(find.text('SIREN'), findsOneWidget);
    expect(find.text('System for Issue Reporting\nand Engineering Notification'),
        findsOneWidget);
    expect(find.text('Initializing...'), findsOneWidget);
  });
}
