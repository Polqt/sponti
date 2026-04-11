import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_card.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';

class GroupPlansScreen extends ConsumerWidget {
  const GroupPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(userGroupPlansProvider);

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      foregroundColor: SpontiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Let's Go Plans",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan where to go with your crew',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SpontiColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: plansAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: SpontiColors.primary),
                ),
                error: (error, _) => AppErrorState(message: error.toString()),
                data: (plans) {
                  if (plans.isEmpty) {
                    return AppEmptyState(
                      emoji: '🗺️',
                      title: 'No plans yet',
                      subtitle:
                          'Start a plan and invite your crew to vote on where to go.',
                      actionLabel: 'Create a plan',
                      onAction: () async {
                        await context.push(RouteName.createGroupPlan);
                        ref.invalidate(userGroupPlansProvider);
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: plans.length,
                    itemBuilder: (context, index) => GroupPlanCard(
                      plan: plans[index],
                      onTap: () => context.push(
                        RouteName.groupPlanDetailPath(plans[index].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _CreatePlanFab(
        onPressed: () async {
          await context.push(RouteName.createGroupPlan);
          ref.invalidate(userGroupPlansProvider);
        },
      ),
    );
  }
}

class _CreatePlanFab extends StatelessWidget {
  const _CreatePlanFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SpontiColors.primary, SpontiColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: SpontiColors.primary.withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'New Plan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
