import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sponti/features/onboarding/presentation/screens/video_onboarding_screen.dart';
import 'package:sponti/features/onboarding/data/datasources/onboarding_local_datasource.dart';

abstract final class Routes {
  static const String videoOnboarding = '/video-onboarding';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String home = '/';
  static const String explore = '/explore';
  static const String profile = '/profile';
  static const String map = '/map';
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
    print('🔄 Router redirect called for: ${state.matchedLocation}');
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isOnVideoOnboarding = state.matchedLocation == Routes.videoOnboarding;
    final isOnAuthRoute =
        state.matchedLocation == Routes.signIn ||
        state.matchedLocation == Routes.onboarding;

    // Check if user has completed onboarding video
    final datasource = OnboardingLocalDatasourceImpl();
    final hasCompletedOnboarding =
        await datasource.hasCompletedOnboarding();

    print('📊 Auth status: $isAuth, Onboarding completed: $hasCompletedOnboarding');

    // If user hasn't completed video onboarding and not already on that screen, redirect there
    if (!hasCompletedOnboarding && !isOnVideoOnboarding) {
      print('🎬 Redirecting to video onboarding');
      return Routes.videoOnboarding;
    }

    // Allow user to stay on video onboarding screen to watch it
    // The screen itself will navigate to sign-in when "Start Exploring" is tapped
    if (isOnVideoOnboarding) {
      print('✅ Allowing video onboarding screen to load');
      return null;
    }

    // If the user is not authenticated and trying to access a protected route, redirect to sign-in
    if (!isAuth && !isOnAuthRoute) return Routes.signIn;

    // If the user is authenticated and trying to access an auth route, redirect to home
    if (isAuth && isOnAuthRoute) return Routes.home;

    print('✅ No redirect needed');
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.videoOnboarding,
      builder: (context, state) => const VideoOnboardingScreen(),
    ),
    // Public routes

    // Full screen routes (outside shell)

    // Shell with bottom nav
  ],
);
