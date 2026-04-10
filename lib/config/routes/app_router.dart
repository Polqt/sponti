import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/config/shell/main_shell.dart';
import 'package:sponti/features/auth/view/screens/sign_in_screen.dart';
import 'package:sponti/features/check_in/view/screens/check_in_page.dart';
import 'package:sponti/features/check_in/view/screens/my_check_ins_screen.dart';
import 'package:sponti/features/discovery/view/screens/discovery_screen.dart';
import 'package:sponti/features/favorites/view/screens/favorites_screen.dart';
import 'package:sponti/features/group_plans/view/screens/create_group_plan_screen.dart';
import 'package:sponti/features/group_plans/view/screens/group_plan_detail_screen.dart';
import 'package:sponti/features/group_plans/view/screens/group_plans_screen.dart';
import 'package:sponti/features/location_comparison/view/screens/location_comparison_screen.dart';
import 'package:sponti/features/locations/view/screens/location_detail.dart';
import 'package:sponti/features/locations/view/screens/location_screen.dart';
import 'package:sponti/features/onboarding/repository/onboarding_local_data_source.dart';
import 'package:sponti/features/onboarding/view/screens/video_onboarding_screen.dart';
import 'package:sponti/features/friends/view/screens/friends_screen.dart';
import 'package:sponti/features/profile/view/screens/edit_profile_screen.dart';
import 'package:sponti/features/profile/view/screens/profile_screen.dart';
import 'package:sponti/features/reviews/view/screens/reviews_screen.dart';
import 'package:sponti/features/search/view/screens/search_screen.dart';
import 'package:sponti/features/suggestions/view/suggest_spot_screen.dart';
import 'package:sponti/features/surprise_me/view/screens/surprise_me_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _onboardingDataSource = OnboardingLocalDataSourceImpl();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteName.location,
  debugLogDiagnostics: kDebugMode,
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final currentPath = state.matchedLocation;
    final isOnVideoOnboarding = currentPath == RouteName.videoOnboarding;
    final isOnSignIn = currentPath == RouteName.signin;
    final isOnAuthRoute = isOnSignIn || isOnVideoOnboarding;

    final hasCompletedOnboarding = await _onboardingDataSource.hasCompletedOnboarding();

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
      path: RouteName.userProfile,
      builder: (context, state) {
        final userId = state.pathParameters['id'] ?? '';
        return ProfileScreen(userId: userId);
      },
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
      path: RouteName.search,
      builder: (context, state) {
        final planId = state.uri.queryParameters['planId'];
        return SearchScreen(voteForPlanId: planId);
      },
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
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.myCheckIns,
      builder: (context, state) => const MyCheckInsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.locationComparison,
      builder: (context, state) => const LocationComparisonScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.groupPlans,
      builder: (context, state) => const GroupPlansScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.createGroupPlan,
      builder: (context, state) => const CreateGroupPlanScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.friends,
      builder: (context, state) => const FriendsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.groupPlanDetail,
      builder: (context, state) {
        final planId = state.pathParameters['id'] ?? '';
        return GroupPlanDetailScreen(planId: planId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: RouteName.locationDetail,
      builder: (context, state) {
        final locationId = state.pathParameters['id'] ?? '';
        return LocationDetailPage(locationId: locationId);
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
              const NoTransitionPage(child: DiscoveryScreen()),
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
