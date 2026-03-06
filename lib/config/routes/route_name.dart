// Usage: This file defines all the route names used in the app. 
// It provides a centralized place to manage route paths, making it easier to maintain and update routes as needed.
// context.go(RouteName.home);

abstract final class RouteName {
  // Authentication
  static const String onboarding = '/onboarding';
  static const String signin = '/signin';

  // Tabs
  static const String location = '/location'; // Acting as home route
  static const String discovery = '/discovery'; 
  static const String explore = '/explore';
  static const String favorites = '/favorites';
  static const String profile = '/profile';

  // Full Screen Routes
  static const String locationDetail = '/locations/:id';
  static const String search = '/search';
  static const String suggest = '/suggest';
  static const String surprise = '/surprise';

  // Helpers
  static String locationDetailPath(String id) => '/locations/$id';
}
