import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'constants/routes_constant.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import "services/logger_service.dart";
import 'utils/utils.dart';

final GoRouter router = GoRouter(
  initialLocation: RouteConstants.home,
  refreshListenable: AuthProvider(),
  redirect: (context, state) async {
    logger.info('Redirecting to ${state.path}');
    final isAuthenticated = await Utils.checkAuthentication();
    if (!isAuthenticated && state.path != RouteConstants.login) {
      return RouteConstants.login;
    }
    return null;
  },
  routes: <GoRoute>[
    GoRoute(
      path: RouteConstants.home,
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: RouteConstants.login,
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
  ],
);
