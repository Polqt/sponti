import 'package:flutter/material.dart';

/// Spot detail screen – name, category, address, open status, etc. (Phase 3).
class SpotDetailScreen extends StatelessWidget {
  const SpotDetailScreen({super.key, required this.spotId});

  final String spotId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot')),
      body: Center(child: Text('Spot: $spotId')),
    );
  }
}
