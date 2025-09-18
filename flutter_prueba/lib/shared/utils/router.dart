import 'package:flutter/material.dart';
import 'package:flutter_prueba/pages/login/login.page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
     
    ),
  ],
);
