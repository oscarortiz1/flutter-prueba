import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prueba/pages/login/login.page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_prueba/pages/login/bloc/login_bloc.dart';

void main() {
  testWidgets('LoginPage renders and has email/password fields', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: BlocProvider(create: (_) => LoginBloc(), child: const LoginPage())));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Enviar código'), findsOneWidget);
  });
}
