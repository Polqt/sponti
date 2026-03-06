import 'package:intl/intl.dart';

// Static formatting utils used across the app.
abstract final class SpontiFormatter {
  // Distance

  // Formats a distance in km to a human-readable string
  // - < 1km -> "500m"
  static String distance(double km) {
    if (km < 1) {
      final meters = (km * 1000).round();
      return '${meters}m';
    } else if (km < 10) {
      return '${km.toStringAsFixed(1)}km';
    } else {
      return '${km.toStringAsFixed(1)}km';
    }
  }

  // Rating
  static String rating(double value) => value.toStringAsFixed(1);

  // Formats a rating (0-5) to a string with 1 decimal place
  static String reviewCount(int count) {
    if (count < 1000) return count.toString();
    return '${(count / 1000).toStringAsFixed(1)}k';
  }

  // Date & Time
  static String date(DateTime dt) => DateFormat('MMMM d, y').format(dt);
  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);

  static String dateTime(DateTime dt) => '${date(dt)} at ${time(dt)}';

  static String operatingHours(String open, String close) {
    final openTime = _parseTime(open);
    final closeTime = _parseTime(close);
    return '$openTime - $closeTime';
  }

  static String _parseTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  // Compact large numbers: 1234 → "1.2k", 1_200_000 → "1.2M"
  static String compactNumber(int n) {
    if (n < 1000) return n.toString();
    if (n < 1_000_000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1_000_000).toStringAsFixed(1)}M';
  }

  // Check in count
  static String checkIns(int count) =>
      '${compactNumber(count)} ${count == 1 ? 'check-in' : 'check-ins'}';

  // Days
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  // Full day name for weekday index (1=Mon … 7=Sun)
  static String dayName(int weekday) => _dayNames[(weekday - 1).clamp(0, 6)];

  // Single initial for weekday index
  static String dayInitial(int weekday) =>
      _dayInitials[(weekday - 1).clamp(0, 6)];
}
