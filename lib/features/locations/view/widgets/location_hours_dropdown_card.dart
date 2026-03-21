import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/formatters.dart';
import 'package:sponti/features/locations/model/location.dart';

class LocationHoursDropdownCard extends StatefulWidget {
  const LocationHoursDropdownCard({
    super.key,
    required this.hours,
  });

  final OperatingHours hours;

  @override
  State<LocationHoursDropdownCard> createState() =>
      _LocationHoursDropdownCardState();
}

class _LocationHoursDropdownCardState extends State<LocationHoursDropdownCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = widget.hours;
    final isOpen = hours.isOpenNow;
    final statusColor = isOpen ? SpontiColors.success : SpontiColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(16),
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
              Expanded(
                child: Text(
                  'Opening hours',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isOpen ? 'Open now' : 'Closed',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                visualDensity: VisualDensity.compact,
                color: SpontiColors.textSecondary,
              ),
            ],
          ),
          Text(
            SpontiFormatter.operatingHours(hours.openTime, hours.closeTime),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            _DayIndicatorRow(daysOpen: hours.daysOpen),
            if (hours.specialNote != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SpontiColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hours.specialNote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SpontiColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ],
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
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final isOpen = daysOpen.contains(weekday);
        final isToday = weekday == today;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isOpen
                  ? SpontiColors.primary
                  : SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: SpontiColors.primary, width: 2)
                  : null,
            ),
            child: Text(
              SpontiFormatter.dayInitial(weekday),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isOpen ? Colors.white : SpontiColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}
