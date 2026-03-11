import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';

class OperatingHoursWidget extends StatelessWidget {
  const OperatingHoursWidget({
    super.key,
    required this.hours,
    this.compact = false,
  });

  final OperatingHours hours;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactHours(hours: hours);
    return _FullHours(hours: hours);
  }
}

class _CompactHours extends StatelessWidget {
  const _CompactHours({required this.hours});
  final OperatingHours hours;

  @override
  Widget build(BuildContext context) {
    final isOpen = hours.isOpenNow;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isOpen ? SpontiColors.success : SpontiColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isOpen ? 'Open Now' : 'Closed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isOpen ? SpontiColors.success : SpontiColors.error,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Â· ${SpontiFormatter.operatingHours(hours.openTime, hours.closeTime)}',
          style: const TextStyle(fontSize: 12, color: SpontiColors.textMuted),
        ),
      ],
    );
  }
}

class _FullHours extends StatelessWidget {
  const _FullHours({required this.hours});
  final OperatingHours hours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = hours.isOpenNow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpontiColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: SpontiColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Hours', style: theme.textTheme.titleMedium),
              const Spacer(),
              _StatusChip(isOpen: isOpen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                SpontiFormatter.operatingHours(hours.openTime, hours.closeTime),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _DayIndicatorRow(daysOpen: hours.daysOpen),
            ],
          ),
          if (hours.specialNote != null) ...[
            const SizedBox(height: 8),
            Text(
              '* ${hours.specialNote}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? SpontiColors.success : SpontiColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isOpen ? 'Open now' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DayIndicatorRow extends StatelessWidget {
  const _DayIndicatorRow({required this.daysOpen});
  final List<int> daysOpen;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final weekday = i + 1;
        final isOpen = daysOpen.contains(weekday);
        final isToday = weekday == today;

        return Container(
          margin: const EdgeInsets.only(left: 3),
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOpen ? SpontiColors.primary : SpontiColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: SpontiColors.primary, width: 2)
                : null,
          ),
          child: Text(
            SpontiFormatter.dayInitial(weekday),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isOpen ? Colors.white : SpontiColors.textMuted,
            ),
          ),
        );
      }),
    );
  }
}
