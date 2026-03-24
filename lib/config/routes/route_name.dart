abstract final class RouteName {
  static const String videoOnboarding = '/video-onboarding';
  static const String onboarding = '/onboarding';
  static const String signin = '/signin';

  static const String location = '/location';
  static const String discovery = '/discovery';
  static const String explore = '/explore';
  static const String favorites = '/favorites';
  static const String myCheckIns = '/my-check-ins';
  static const String profile = '/profile';

  static const String locationDetail = '/locations/:id';
  static const String editProfile = '/edit-profile';
  static const String search = '/search';
  static const String suggest = '/suggest';
  static const String suggestSpot = '/suggest-spot';
  static const String surprise = '/surprise';

  static String locationDetailPath(String id) => '/locations/$id';

  static const String checkIn = '/check-in';
  static String checkInPath({
    required String locationId,
    required String locationName,
  }) =>
      '/check-in?locationId=$locationId&locationName=${Uri.encodeComponent(locationName)}';

  static const String reviews = '/reviews';
  static String reviewsPath({
    required String locationId,
    required String locationName,
  }) =>
      '/reviews?locationId=$locationId&locationName=${Uri.encodeComponent(locationName)}';
}


