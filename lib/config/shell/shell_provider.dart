import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/config/routes/route_name.dart';

/// The shell tabs in order, index must match the bottom nav order.
enum ShellTab {
  location(0, RouteName.location),
  discovery(1, RouteName.discovery),
  favorites(2, RouteName.favorites),
  profile(3, RouteName.profile);

  const ShellTab(this.tabIndex, this.route);

  final int tabIndex;
  final String route;

  /// Resolves the correct tab from a current router location string.
  static ShellTab fromLocation(String location) {
    return ShellTab.values.firstWhere(
      (t) => location.startsWith(t.route),
      orElse: () => ShellTab.location,
    );
  }
}

/// Tracks which bottom nav tab is currently active.
/// Updated by [MainShell] on every tab tap.
final activeTabProvider = StateProvider<int>((ref) => 0);

/// Controls global shell chrome visibility for immersive screens (e.g. map sheets).
/// 0.0 = fully visible, 1.0 = fully hidden.
final shellChromeProgressProvider = StateProvider<double>((ref) => 0.0);
