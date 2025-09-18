// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_prueba/main.dart';
import 'package:flutter_prueba/shared/services/api_service.dart';

// initialize ApiService for tests
void _ensureApi() {
  try {
    ApiService.init(baseUrl: 'http://localhost:3000');
  } catch (_) {}
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
  _ensureApi();
  await tester.pumpWidget(const MyApp());
  // Basic smoke: verify app builds and contains a Scaffold
  await tester.pumpAndSettle();
  expect(find.byType(Scaffold), findsOneWidget);
  });
}
