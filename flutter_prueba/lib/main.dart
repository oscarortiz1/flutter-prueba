import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_prueba/shared/utils/router.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pages/login/bloc/login_bloc.dart';
import 'shared/utils/theme.dart';
import 'shared/services/api_service.dart';
import 'shared/services/sync_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables (optional `.env`) and initialize API client.
  await dotenv.load();
 
  String baseUrl =  dotenv.env['BASE_URL']!;
 
  
  // ignore: avoid_print
  print('ApiService baseUrl set to: $baseUrl');
  ApiService.init(baseUrl: baseUrl);

  // Start periodic background sync
  final sync = SyncService();
  sync.startAutoSync(interval: const Duration(seconds: 30));

  // Try to restore session using refresh token before launching UI
  try {
    await AuthService().tryRestoreSession();
  } catch (_) {}

  // If there was a queued sync from offline, try to consume it now
  try {
    await sync.tryConsumeQueuedSync();
  } catch (_) {}

  // Load theme mode
  final themeService = ThemeService();
  await themeService.load();

  // Build router after session restore so redirect sees correct auth state
  final router = buildRouter();

  runApp(BlocProvider(
    create: (_) => LoginBloc(),
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.mode,
      builder: (context, mode, _) => MyApp(themeMode: mode, router: router),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.themeMode = ThemeMode.system, this.router});
  final ThemeMode themeMode;
  final router;
  @override
  Widget build(BuildContext context) {
    if (router == null) {
      // In test environments we may not pass a router; fall back to a simple MaterialApp
      return MaterialApp(
        home: const Scaffold(body: SizedBox.shrink()),
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
      );
    }
    return MaterialApp.router(
      routerConfig: router,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    );
  }
}
