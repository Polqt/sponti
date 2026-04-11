import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/providers/connectivity_provider.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_create_widgets.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_offline_banner.dart';
import 'package:sponti/features/group_plans/view/widgets/group_plan_page_header.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';

class CreateGroupPlanScreen extends ConsumerStatefulWidget {
  const CreateGroupPlanScreen({super.key});

  @override
  ConsumerState<CreateGroupPlanScreen> createState() =>
      _CreateGroupPlanScreenState();
}

class _CreateGroupPlanScreenState extends ConsumerState<CreateGroupPlanScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPlan() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    final isConnected = await ref.read(isConnectedProvider.future);
    if (!isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Connect to create a group plan.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final repo = ref.read(groupPlansRepositoryProvider);
    final result = await repo.createGroupPlan(
      name: name,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.message}')),
        );
        setState(() => _isLoading = false);
      },
      (plan) {
        ref.invalidate(userGroupPlansProvider);
        context.pushReplacement(RouteName.groupPlanDetailPath(plan.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GroupPlanPageHeader(
              title: 'New Plan',
              subtitle: 'Decide where your crew is heading',
            ),
            if (!isOnline)
              const GroupPlanOfflineBanner(
                message:
                    'You are offline. You can draft the details now, but plan creation needs a connection.',
              ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Plan name'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _nameController,
                      hint: 'e.g. Friday night out',
                      enabled: !_isLoading,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(label: 'Description'),
                    const SizedBox(height: 2),
                    Text(
                      'Optional - add a note for your crew',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SpontiColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _descriptionController,
                      hint: 'Add any details or vibe check...',
                      enabled: !_isLoading,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    const GroupPlanHowItWorksCard(),
                    const SizedBox(height: 24),
                    GroupPlanCreateButton(
                      isLoading: _isLoading,
                      isOnline: isOnline,
                      onTap: _createPlan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: SpontiColors.textPrimary,
            letterSpacing: 0.1,
          ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.enabled,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final int maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: SpontiColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: SpontiColors.textMuted,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: SpontiColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpontiColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpontiColors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SpontiColors.outline.withValues(alpha: 0.5),
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
