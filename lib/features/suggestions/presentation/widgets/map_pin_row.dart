import 'package:flutter/material.dart';

class MapPinRow extends StatelessWidget {
  const MapPinRow({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_outlined, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPin
                    ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                    : 'drop a pin on map (optional)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8A8A)),
          ],
        ),
      ),
    );
  }
}
