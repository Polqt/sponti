import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/features/locations/presentation/screens/location_screen.dart';

abstract final class Routes {
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';

  static const String explore = '/explore';
  static const String location = '/location';
  static const String profile = '/profile';
  static const String discovery = '/discovery';
  static const String favorites = '/favorites';

  static const String spotDetail = '/spot/:id';
  static const String surprise = '/surprise';
}

// Navigator keys for each route, used for navigation and state management
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Router configuration using GoRouter
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.location,
  debugLogDiagnostics: true,
  // redirect: (context, state) {
  //   final session = Supabase.instance.client.auth.currentSession;
  //   final isAuth = session != null;
  //   final isOnAuthRoute =
  //       state.matchedLocation == Routes.signIn ||
  //       state.matchedLocation == Routes.onboarding;

  //   // If the user is not authenticated and trying to access a protected route, redirect to onboarding
  //   if (!isAuth && !isOnAuthRoute) return Routes.signIn;

  //   // If the user is authenticated and trying to access an auth route, redirect to home
  //   if (isAuth && isOnAuthRoute) return Routes.home;
  //   return null;
  // },
  routes: [
    // Public routes
    // GoRoute(path: RouteName.onboarding),
    // GoRoute(path: RouteName.signin),

    // Full screen routes (outside shell)
    // GoRoute(
    //   parentNavigatorKey: _rootNavigatorKey,
    //   path: RouteName.locationDetail,
    // ),
    // GoRoute(parentNavigatorKey: _rootNavigatorKey, path: RouteName.search),
    // GoRoute(parentNavigatorKey: _rootNavigatorKey, path: RouteName.suggest),
    // GoRoute(parentNavigatorKey: _rootNavigatorKey, path: RouteName.surprise),

    // Shell with bottom nav
    GoRoute(path: RouteName.location, builder: (context, state) => const LocationScreen()),
    // GoRoute(path: RouteName.discovery),
    // GoRoute(path: RouteName.explore),
    // GoRoute(path: RouteName.favorites),
    // GoRoute(path: RouteName.profile),
  ],
);
