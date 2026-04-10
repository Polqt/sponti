import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';

class CreateGroupPlanScreen extends ConsumerStatefulWidget {
  const CreateGroupPlanScreen({super.key});

  @override
  ConsumerState<CreateGroupPlanScreen> createState() =>
      _CreateGroupPlanScreenState();
}

class _CreateGroupPlanScreenState extends ConsumerState<CreateGroupPlanScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
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
    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: SpontiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'New Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'Decide where your crew is heading',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SpontiColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ── Form ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Plan name'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _nameController,
                      hint: 'e.g. Friday night out 🍕',
                      enabled: !_isLoading,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Description'),
                    const SizedBox(height: 2),
                    Text(
                      'Optional — add a note for your crew',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SpontiColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _descriptionController,
                      hint: 'Add any details or vibe check…',
                      enabled: !_isLoading,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    _HowItWorksCard(),
                    const SizedBox(height: 24),
                    // ── CTA inline with content ────────────────
                    _CreateButton(
                      isLoading: _isLoading,
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

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    SpontiColors.primary.withValues(alpha: 0.6),
                    SpontiColors.primaryLight.withValues(alpha: 0.6),
                  ]
                : const [SpontiColors.primary, SpontiColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: isLoading
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
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Let's Go",
                      style: TextStyle(
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

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  static const _steps = [
    ('1', 'Create a plan and invite your friends'),
    ('2', 'Everyone nominates & votes for a location'),
    ('3', 'The top vote wins — lock it in!'),
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
            (s) => Padding(
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
                      s.$1,
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
                      s.$2,
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
