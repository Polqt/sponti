import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class Routes {
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String map = '/map';
}

// Navigator keys for each route, used for navigation and state management
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Router configuration using GoRouter
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: Routes.onboarding,
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isOnAuthRoute = state.matchedLocation == Routes.signIn || state.matchedLocation == Routes.onboarding;

    // If the user is not authenticated and trying to access a protected route, redirect to onboarding
    if (!isAuth && !isOnAuthRoute) return Routes.signIn;

    // If the user is authenticated and trying to access an auth route, redirect to home
    if (isAuth && isOnAuthRoute) return Routes.home;
    return null;
  },
  routes: [
    // Public routes
  ]
);
