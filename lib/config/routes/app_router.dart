import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/main_shell.dart';
import 'package:sponti/features/auth/view/screens/sign_in_screen.dart';
import 'package:sponti/features/discovery/view/screens/map_screen.dart';
import 'package:sponti/features/discovery/view/screens/surprise_screen.dart';
import 'package:sponti/features/explore/view/screens/explore_screen.dart';
import 'package:sponti/features/favorites/view/screens/favorites_screen.dart';
import 'package:sponti/features/locations/view/screens/location_detail_screen.dart';
import 'package:sponti/features/locations/view/screens/location_screen.dart';
import 'package:sponti/features/onboarding/repository/onboarding_local_data_source.dart';
import 'package:sponti/features/onboarding/view/screens/video_onboarding_screen.dart';
import 'package:sponti/features/profile/view/screens/edit_profile_screen.dart';
import 'package:sponti/features/profile/view/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class Routes {
  static const String videoOnboarding = '/video-onboarding';
  static const String signIn = '/signin';
  static const String location = '/location';

  static const String profile = '/profile';
  static const String discovery = '/discovery';
  static const String explore = '/explore';
  static const String favorites = '/favorites';

  static const String spotDetail = '/spot/:id';
  static const String surprise = '/surprise';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.location,
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isOnVideoOnboarding = state.matchedLocation == Routes.videoOnboarding;
    final isOnAuthRoute =
        state.matchedLocation == Routes.signIn ||
        state.matchedLocation == Routes.videoOnboarding;

    final dataSource = OnboardingLocalDataSourceImpl();
    final hasCompletedOnboarding = await dataSource.hasCompletedOnboarding();

    if (!hasCompletedOnboarding && !isOnVideoOnboarding) {
      return Routes.videoOnboarding;
    }

    if (isOnVideoOnboarding) return null;
    if (!isAuth && !isOnAuthRoute) return Routes.signIn;
    if (isAuth && isOnAuthRoute) return Routes.location;

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
      path: RouteName.locationDetail,
      builder: (context, state) =>
          LocationDetailScreen(id: state.pathParameters['id']!),
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
          path: RouteName.explore,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ExploreScreen()),
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
