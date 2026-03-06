import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/routes/route_name.dart';


/// The shell tabs in order, index must match the bottom nav order.
enum ShellTab {
  home(0, RouteName.home),
  explore(1, RouteName.explore),
  map(2, RouteName.map),
  favorites(3, RouteName.favorites),
  profile(4, RouteName.profile);

  const ShellTab(this.tabIndex, this.route);

  final int tabIndex;
  final String route;

  /// Resolves the correct tab from a current router location string.
  static ShellTab fromLocation(String location) {
    return ShellTab.values.firstWhere(
      (t) => location.startsWith(t.route),
      orElse: () => ShellTab.home,
    );
  }
}

/// Tracks which bottom nav tab is currently active.
/// Updated by [MainShell] on every tab tap.
final activeTabProvider = StateProvider<int>((ref) => 0);
