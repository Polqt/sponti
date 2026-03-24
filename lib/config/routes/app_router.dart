import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/main_shell.dart';
import 'package:sponti/features/auth/view/screens/sign_in_screen.dart';
import 'package:sponti/features/check_in/view/screens/check_in_page.dart';
import 'package:sponti/features/discovery/view/screens/map_screen.dart';
import 'package:sponti/features/discovery/view/screens/surprise_screen.dart';
import 'package:sponti/features/favorites/view/screens/favorites_screen.dart';
import 'package:sponti/features/locations/view/screens/location_screen.dart';
import 'package:sponti/features/onboarding/repository/onboarding_local_data_source.dart';
import 'package:sponti/features/onboarding/view/screens/video_onboarding_screen.dart';
import 'package:sponti/features/profile/view/screens/edit_profile_screen.dart';
import 'package:sponti/features/profile/view/screens/profile_screen.dart';
import 'package:sponti/features/reviews/view/screens/reviews_screen.dart';
import 'package:sponti/features/suggestions/view/suggest_spot_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteName.location,
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final currentPath = state.matchedLocation;
    final isOnVideoOnboarding = currentPath == RouteName.videoOnboarding;
    final isOnSignIn = currentPath == RouteName.signin;
    final isOnAuthRoute = isOnSignIn || isOnVideoOnboarding;

    final dataSource = OnboardingLocalDataSourceImpl();
    final hasCompletedOnboarding = await dataSource.hasCompletedOnboarding();

    if (!hasCompletedOnboarding && !isOnVideoOnboarding) {
      return RouteName.videoOnboarding;
    }

    if (hasCompletedOnboarding && isOnVideoOnboarding) {
      return isAuth ? RouteName.location : RouteName.signin;
    }

    if (!isAuth && !isOnAuthRoute) return RouteName.signin;
    if (isAuth && isOnAuthRoute) return RouteName.location;

    return null;
  },
  routes: [
    GoRoute(
      path: RouteName.videoOnboarding,
      builder: (context, state) => const VideoOnboardingScreen(),
    ),
    GoRoute(
      path: RouteName.signin,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.surprise,
      builder: (context, state) => const SurpriseScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.suggestSpot,
      builder: (context, state) => const SuggestSpotScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.checkIn,
      builder: (context, state) {
        final locationId = state.uri.queryParameters['locationId'] ?? '';
        final locationName = state.uri.queryParameters['locationName'] ?? '';
        return CheckInPage(
          locationId: locationId,
          locationName: Uri.decodeComponent(locationName),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.reviews,
      builder: (context, state) {
        final locationId = state.uri.queryParameters['locationId'] ?? '';
        final locationName = state.uri.queryParameters['locationName'] ?? '';
        return ReviewsScreen(
          locationId: locationId,
          locationName: Uri.decodeComponent(locationName),
        );
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: RouteName.location,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LocationScreen()),
        ),
        GoRoute(
          path: RouteName.discovery,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MapScreen()),
        ),
        GoRoute(
          path: RouteName.favorites,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FavoritesScreen()),
        ),
        GoRoute(
          path: RouteName.profile,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
  ],
);
