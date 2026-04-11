import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/providers/connectivity_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_empty_state.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_card.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_offline_banner.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_page_header.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';

class GroupPlansScreen extends ConsumerWidget {
  const GroupPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(userGroupPlansProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    Future<void> openCreatePlan() async {
      await context.push(RouteName.createGroupPlan);
      ref.invalidate(userGroupPlansProvider);
    }

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GroupPlanPageHeader(
              title: "Let's Go Plans",
              subtitle: 'Plan where to go with your crew',
            ),
            if (!isOnline) const GroupPlanOfflineBanner(),
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
                      emoji: '\u{1F5FA}\u{FE0F}',
                      title: 'No plans yet',
                      subtitle:
                          'Start a plan and invite your crew to vote on where to go.',
                      actionLabel: isOnline ? 'Create a plan' : null,
                      onAction: isOnline ? openCreatePlan : null,
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
        isEnabled: isOnline,
        onPressed: openCreatePlan,
      ),
    );
  }
}

class _CreatePlanFab extends StatelessWidget {
  const _CreatePlanFab({
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? const [SpontiColors.primary, SpontiColors.primaryLight]
                : [
                    SpontiColors.primary.withValues(alpha: 0.55),
                    SpontiColors.primaryLight.withValues(alpha: 0.55),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: SpontiColors.primary.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              isEnabled ? 'New Plan' : 'Offline',
              style: const TextStyle(
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
