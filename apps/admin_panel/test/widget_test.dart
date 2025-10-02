import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_panel/main.dart';

void main() {
  testWidgets('Admin Panel smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdminPanelApp());

    // Verify that the dashboard loads
    expect(find.text('لوحة التحكم'), findsOneWidget);
    
    // Verify that the app bar exists
    expect(find.byType(AppBar), findsOneWidget);
  });
}
