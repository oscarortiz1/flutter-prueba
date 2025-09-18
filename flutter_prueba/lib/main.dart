import 'package:flutter/material.dart';
import 'package:flutter_prueba/shared/utils/router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pages/login/bloc/login_bloc.dart';
import 'shared/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BlocProvider(create: (_) => LoginBloc(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
