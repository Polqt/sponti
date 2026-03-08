import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:sponti/features/locations/presentation/screens/location_screen.dart';
import 'package:sponti/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:sponti/features/onboarding/presentation/screens/video_onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class Routes {
  static const String videoOnboarding = '/video-onboarding';
  static const String signIn = '/signin';
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
  initialLocation: Routes.videoOnboarding,
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isOnVideoOnboarding = state.matchedLocation == Routes.videoOnboarding;
    final isOnAuthRoute =
        state.matchedLocation == Routes.signIn ||
        state.matchedLocation == Routes.videoOnboarding;

    // Check if user has completed onboarding video
    final datasource = OnboardingLocalDatasourceImpl();
    final hasCompletedOnboarding = await datasource.hasCompletedOnboarding();

    // If user hasn't completed video onboarding and not already on that screen, redirect there
    if (!hasCompletedOnboarding && !isOnVideoOnboarding) {
      return Routes.videoOnboarding;
    }

    // Allow user to stay on video onboarding screen to watch it
    // The screen itself will navigate to sign-in when "Start Exploring" is tapped
    if (isOnVideoOnboarding) {
      return null;
    }

    // If the user is not authenticated and trying to access a protected route, redirect to sign-in
    if (!isAuth && !isOnAuthRoute) return Routes.signIn;

    // If the user is authenticated and trying to access an auth route, redirect to home
    if (isAuth && isOnAuthRoute) return Routes.location;

    return null;
  },
  routes: [
    // Onboarding
    GoRoute(
      path: RouteName.videoOnboarding,
      builder: (context, state) => const VideoOnboardingScreen(),
    ),

    // Auth
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
