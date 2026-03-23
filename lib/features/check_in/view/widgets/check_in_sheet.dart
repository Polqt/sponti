import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/app_button.dart';
import 'package:sponti/features/check_in/viewmodel/checkins_viewmodel.dart';

Future<void> showCheckInSheet(
  BuildContext context, {
  required String locationId,
  required String locationName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CheckInSheet(
      locationId: locationId,
      locationName: locationName,
    ),
  );
}

class _CheckInSheet extends ConsumerStatefulWidget {
  const _CheckInSheet({
    required this.locationId,
    required this.locationName,
  });

  final String locationId;
  final String locationName;

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    final notifier = ref.read(checkInProvider(widget.locationId).notifier);
    final success = await notifier.checkIn(note: note.isEmpty ? null : note);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkInProvider(widget.locationId));
    final isLoading = state.valueOrNull?.isLoading ?? false;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: SpontiColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: SpontiColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header row: location name + close
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.locationName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SpontiColors.textPrimary,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: SpontiColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab pills: save for later | visited (visited is active)
          _TabPills(activeIndex: 1, onTap: (_) {}),
          const SizedBox(height: 24),

          // Note field with avatar
          _NoteField(controller: _noteController),
          const SizedBox(height: 24),

          // Save button
          AppButton(
            label: 'save',
            prefixIcon: Icons.check_circle_outline_rounded,
            size: AppButtonSize.large,
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _TabPills extends StatelessWidget {
  const _TabPills({required this.activeIndex, required this.onTap});

  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _Pill(
            label: 'save for later',
            icon: Icons.bookmark_border_rounded,
            isActive: activeIndex == 0,
            onTap: () => onTap(0),
          ),
          _Pill(
            label: 'visited',
            icon: Icons.check_rounded,
            isActive: activeIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? SpontiColors.dark : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? SpontiColors.white
                    : SpontiColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? SpontiColors.white
                      : SpontiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar placeholder
        CircleAvatar(
          radius: 18,
          backgroundColor: SpontiColors.surfaceVariant,
          child: const Icon(
            Icons.person_rounded,
            size: 18,
            color: SpontiColors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(
              fontSize: 14,
              color: SpontiColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'what do you think?',
              hintStyle: TextStyle(
                fontSize: 14,
                color: SpontiColors.textMuted.withValues(alpha: 0.7),
              ),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: SpontiColors.outline,
                  style: BorderStyle.solid,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: SpontiColors.secondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
