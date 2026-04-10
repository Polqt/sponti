import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class AmenitiesFilterSelection {
  const AmenitiesFilterSelection({
    required this.hasWifi,
    required this.petFriendly,
    required this.hasParking,
  });

  final bool hasWifi;
  final bool petFriendly;
  final bool hasParking;

  int get selectedCount =>
      (hasWifi ? 1 : 0) + (petFriendly ? 1 : 0) + (hasParking ? 1 : 0);

  AmenitiesFilterSelection copyWith({
    bool? hasWifi,
    bool? petFriendly,
    bool? hasParking,
  }) {
    return AmenitiesFilterSelection(
      hasWifi: hasWifi ?? this.hasWifi,
      petFriendly: petFriendly ?? this.petFriendly,
      hasParking: hasParking ?? this.hasParking,
    );
  }
}

Future<AmenitiesFilterSelection?> showAmenitiesFilterModal({
  required BuildContext context,
  required AmenitiesFilterSelection initialValue,
}) {
  return showModalBottomSheet<AmenitiesFilterSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - 24,
    ),
    builder: (_) => _AmenitiesFilterModal(initialValue: initialValue),
  );
}

class _AmenitiesFilterModal extends StatefulWidget {
  const _AmenitiesFilterModal({required this.initialValue});

  final AmenitiesFilterSelection initialValue;

  @override
  State<_AmenitiesFilterModal> createState() => _AmenitiesFilterModalState();
}

class _AmenitiesFilterModalState extends State<_AmenitiesFilterModal> {
  late AmenitiesFilterSelection _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialValue;
  }

  void _toggleWifi() =>
      setState(() => _selection = _selection.copyWith(hasWifi: !_selection.hasWifi));
  void _togglePets() => setState(
    () => _selection = _selection.copyWith(petFriendly: !_selection.petFriendly),
  );
  void _toggleParking() => setState(
    () => _selection = _selection.copyWith(hasParking: !_selection.hasParking),
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const radius = BorderRadius.all(Radius.circular(28));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F1).withValues(alpha: 0.97),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 2),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SpontiColors.textMuted.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Amenities',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SpontiColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pop(widget.initialValue),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: SpontiColors.textMuted.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: SpontiColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x14A68F7B)),
              _AmenitiesRow(
                icon: Icons.wifi_rounded,
                label: 'WiFi',
                subtitle: 'Spots with internet access',
                isSelected: _selection.hasWifi,
                onTap: _toggleWifi,
              ),
              const Divider(height: 1, indent: 64, endIndent: 20),
              _AmenitiesRow(
                icon: Icons.pets_rounded,
                label: 'Pet Friendly',
                subtitle: 'Pets are welcome',
                isSelected: _selection.petFriendly,
                onTap: _togglePets,
              ),
              const Divider(height: 1, indent: 64, endIndent: 20),
              _AmenitiesRow(
                icon: Icons.local_parking_rounded,
                label: 'Parking',
                subtitle: 'Parking available nearby',
                isSelected: _selection.hasParking,
                onTap: _toggleParking,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(
                          () => _selection = const AmenitiesFilterSelection(
                            hasWifi: false,
                            petFriendly: false,
                            hasParking: false,
                          ),
                        ),
                        child: const Text('Clear all'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(_selection),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomInset + 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenitiesRow extends StatelessWidget {
  const _AmenitiesRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = SpontiColors.secondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : SpontiColors.textMuted.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: isSelected ? color : SpontiColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : SpontiColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SpontiColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : SpontiColors.outline,
                    width: isSelected ? 0 : 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
