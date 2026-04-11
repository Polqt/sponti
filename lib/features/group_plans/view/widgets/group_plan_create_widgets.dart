import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class GroupPlanCreateButton extends StatelessWidget {
  const GroupPlanCreateButton({
    required this.isLoading,
    required this.isOnline,
    required this.onTap,
    super.key,
  });

  final bool isLoading;
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || !isOnline;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDisabled
                ? [
                    SpontiColors.primary.withValues(alpha: 0.6),
                    SpontiColors.primaryLight.withValues(alpha: 0.6),
                  ]
                : const [SpontiColors.primary, SpontiColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: SpontiColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      isOnline ? "Let's Go" : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class GroupPlanHowItWorksCard extends StatelessWidget {
  const GroupPlanHowItWorksCard({super.key});

  static const _steps = [
    ('1', 'Create a plan and invite your friends'),
    ('2', 'Friends accept or decline before joining the vote'),
    ('3', 'Accepted members suggest spots and vote for a winner'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpontiColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SpontiColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                size: 15,
                color: SpontiColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'How it works',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SpontiColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: SpontiColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      step.$1,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: SpontiColors.primary,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SpontiColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
