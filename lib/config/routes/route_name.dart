abstract final class RouteName {
  static const String videoOnboarding = '/video-onboarding';
  static const String onboarding = '/onboarding';
  static const String signin = '/signin';

  static const String location = '/location';
  static const String discovery = '/discovery';
  static const String explore = '/explore';
  static const String favorites = '/favorites';
  static const String profile = '/profile';

  static const String locationDetail = '/locations/:id';
  static const String editProfile = '/edit-profile';
  static const String search = '/search';
  static const String suggest = '/suggest';
  static const String surprise = '/surprise';

  static String locationDetailPath(String id) => '/locations/$id';
}
