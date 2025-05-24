// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebk_app/main.dart';

void main() {
  testWidgets('EBK App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EBKApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that key elements are present
    // Check for the logo image in the app bar
    expect(find.byType(Image), findsWidgets);

    // Check for Space Status card (which should be visible)
    expect(find.text('Space Status'), findsOneWidget);

    // Check for Events section (should be present in localized form)
    expect(find.byIcon(Icons.event), findsWidgets);
  });
}
