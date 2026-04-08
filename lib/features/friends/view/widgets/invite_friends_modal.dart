import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/view/widgets/friend_avatar.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';
import 'package:sponti/features/group_plans/models/group_plan.dart';
import 'package:sponti/features/group_plans/viewmodel/group_plans_viewmodel.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

class InviteFriendsModal extends ConsumerStatefulWidget {
  const InviteFriendsModal({
    super.key,
    required this.planId,
    required this.existingParticipantIds,
  });

  final String planId;
  final Set<String> existingParticipantIds;

  static Future<void> show(
    BuildContext context, {
    required String planId,
    required Set<String> existingParticipantIds,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SpontiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteFriendsModal(
        planId: planId,
        existingParticipantIds: existingParticipantIds,
      ),
    );
  }

  @override
  ConsumerState<InviteFriendsModal> createState() => _InviteFriendsModalState();
}

class _InviteFriendsModalState extends ConsumerState<InviteFriendsModal> {
  final Set<String> _inviting = {};
  final Set<String> _invited = {};

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(friendConnectionsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SpontiColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Invite Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SpontiColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: connectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('Could not load friends.',
                    style: TextStyle(color: SpontiColors.textMuted)),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('No friends yet.',
                        style: TextStyle(color: SpontiColors.textMuted)),
                  );
                }
                return ListView.builder(
                  controller: controller,
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final friendId = rows[i]['friend_id'] as String? ?? '';
                    return _FriendInviteTile(
                      friendId: friendId,
                      alreadyIn: widget.existingParticipantIds.contains(friendId) ||
                          _invited.contains(friendId),
                      isInviting: _inviting.contains(friendId),
                      onInvite: () => _invite(friendId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _invite(String friendId) async {
    setState(() => _inviting.add(friendId));
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(groupPlansRepositoryProvider)
        .addParticipant(planId: widget.planId, userId: friendId);
    if (!mounted) return;
    setState(() {
      _inviting.remove(friendId);
      result.fold(
        (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
        (_) => _invited.add(friendId),
      );
    });
    ref.invalidate(groupPlanDetailProvider(widget.planId));
  }
}

class _FriendInviteTile extends ConsumerWidget {
  const _FriendInviteTile({
    required this.friendId,
    required this.alreadyIn,
    required this.isInviting,
    required this.onInvite,
  });

  final String friendId;
  final bool alreadyIn;
  final bool isInviting;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(friendId)).valueOrNull;

    final displayName = profile == null
        ? '…'
        : (profile.username?.isNotEmpty == true
            ? '@${profile.username}'
            : profile.fullName);

    return ListTile(
      leading: FriendAvatar(
        name: profile?.fullName ?? '',
        avatarUrl: profile?.avatarUrl,
        radius: 20,
      ),
      title: Text(
        displayName,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: SpontiColors.textPrimary,
        ),
      ),
      trailing: alreadyIn
          ? const Icon(Icons.check_circle_rounded,
              color: SpontiColors.success, size: 20)
          : FilledButton(
              onPressed: isInviting ? null : onInvite,
              style: FilledButton.styleFrom(
                backgroundColor: SpontiColors.primary,
                foregroundColor: SpontiColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: isInviting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: SpontiColors.white),
                    )
                  : const Text('Invite'),
            ),
    );
  }
}

extension ParticipantIdSet on List<PlanParticipant> {
  Set<String> toIdSet() => map((p) => p.userId).toSet();
}
