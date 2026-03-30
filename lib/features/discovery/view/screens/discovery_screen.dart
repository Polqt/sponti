import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/view/widgets/discovery_body.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: const SafeArea(
        bottom: false,
        child: DiscoveryBody(),
      ),
    );
  }
}
