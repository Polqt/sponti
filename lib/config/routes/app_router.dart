import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:sponti/features/locations/presentation/screens/location_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sponti/features/onboarding/presentation/screens/video_onboarding_screen.dart';
import 'package:sponti/features/onboarding/data/datasources/onboarding_local_datasource.dart';

abstract final class Routes {
  static const String videoOnboarding = '/video-onboarding';
  static const String onboarding = '/onboarding';
  static const String signIn = '/signin';

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
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isOnAuthRoute =
        state.matchedLocation == Routes.signIn ||
        state.matchedLocation == Routes.onboarding;

    // If the user is not authenticated and trying to access a protected route, redirect to onboarding
    if (!isAuth && !isOnAuthRoute) return Routes.signIn;

    // If the user is authenticated and trying to access an auth route, redirect to home
    if (isAuth && isOnAuthRoute) return Routes.location;
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.videoOnboarding,
      builder: (context, state) => const VideoOnboardingScreen(),
    ),
    // Public routes
    // GoRoute(
    //   path: RouteName.onboarding,
    //   builder: (context, state) => const SplashScreen(),
    // ),
    GoRoute(
      path: RouteName.signin,
      builder: (context, state) => const SignInScreen(),
    ),

    // Full screen routes (outside shell)
    // GoRoute(
    //   parentNavigatorKey: _rootNavigatorKey,
    //   path: RouteName.locationDetail,
    //   builder: (context, state) =>
    //       LocationDetailScreen(id: state.pathParameters['id']!),
    // ),
    // GoRoute(
    //   parentNavigatorKey: _rootNavigatorKey,
    //   path: RouteName.search,
    //   builder: (context, state) => const SearchScreen(),
    // ),
    // GoRoute(
    //   parentNavigatorKey: _rootNavigatorKey,
    //   path: RouteName.suggest,
    //   builder: (context, state) => const SuggestScreen(),
    // ),
    // GoRoute(
    //   parentNavigatorKey: _rootNavigatorKey,
    //   path: RouteName.surprise,
    //   builder: (context, state) => const SurpriseScreen(),
    // ),

    // Shell with bottom nav
    GoRoute(
      path: RouteName.location,
      builder: (context, state) => const LocationScreen(),
    ),
    // GoRoute(
    //   path: RouteName.discovery,
    //   builder: (context, state) => const MapScreen(),
    // ),
    // GoRoute(
    //   path: RouteName.explore,
    //   builder: (context, state) => const ExploreScreen(),
    // ),
    // GoRoute(
    //   path: RouteName.favorites,
    //   builder: (context, state) => const FavoritesScreen(),
    // ),
    // GoRoute(
    //   path: RouteName.profile,
    //   builder: (context, state) => const ProfileScreen(),
    // ),
  ],
);
