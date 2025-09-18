import 'package:flutter/material.dart';
import 'package:flutter_prueba/pages/login/login.page.dart';
import 'package:flutter_prueba/pages/register/register.page.dart';
import 'package:flutter_prueba/pages/movements/movements.page.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'package:flutter_prueba/pages/layout/layout.page.dart';
import 'package:flutter_prueba/pages/profile/profile.page.dart';
import 'package:flutter_prueba/pages/settings/settings.page.dart';

// Simple placeholder pages for the shell routes. Replace with your real screens.
// ... use real Profile and Settings pages (imported above)

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      refreshListenable: AuthService.authLoggedIn,
      redirect: (context, state) {
        final loggedIn = AuthService.authLoggedIn.value;
        final path = state.uri.path;
        final loggingIn = path == '/' || path == '/register';
        if (!loggedIn && !loggingIn) return '/';
        if (loggedIn && loggingIn) return '/app/home';
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => const LoginPage(),
        ),
        GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
        ShellRoute(
          builder: (context, state, child) {
            int index = 0;
            final sub = state.uri.path;
            if (sub.startsWith('/app/profile')) index = 1;
            if (sub.startsWith('/app/settings')) index = 2;
            return LayoutPage(
              child: child,
              selectedIndex: index,
              onIndexChanged: (i) {
                switch (i) {
                  case 0:
                    context.go('/app/home');
                    break;
                  case 1:
                    context.go('/app/profile');
                    break;
                  case 2:
                    context.go('/app/settings');
                    break;
                }
              },
            );
          },
          routes: [
            GoRoute(path: '/app/home', builder: (c, s) => const MovementsPage()),
            GoRoute(path: '/app/profile', builder: (c, s) => const ProfilePage()),
            GoRoute(path: '/app/settings', builder: (c, s) => const SettingsPage()),
          ],
        ),
      ],
    );
