import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prueba/pages/movements/movements.page.dart';
import 'package:flutter_prueba/shared/services/api_service.dart';

void main() {
  testWidgets('MovementsPage shows loading when bloc not ready', (WidgetTester tester) async {
    // ensure ApiService exists so SyncService won't throw during init
    try {
      ApiService.init(baseUrl: 'http://localhost:3000');
    } catch (_) {}
    await tester.pumpWidget(MaterialApp(home: const MovementsPage()));
    // initial frame
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
