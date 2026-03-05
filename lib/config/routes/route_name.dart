abstract final class RouteName {
  // Authentication
  static const String onboarding = '/onboarding';
  static const String signin = '/signin';

  // Tabs 
  static const String home = '/home';
  static const String explore = '/explore';
  static const String map = '/map';
  static const String favorites = '/favorites';
  static const String profile = '/profile';

  // Full Screen Routes
  static const String locationDetail = '/location/:id';
  static const String search = '/search';
  static const String suggest = '/suggest';
  static const String surprise = '/surprise';

  // Helpers 
  static String locationDetailPath(String id) => '/location/$id';
}