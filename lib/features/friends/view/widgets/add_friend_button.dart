import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/friends/viewmodel/friends_viewmodel.dart';

class AddFriendButton extends ConsumerWidget {
  const AddFriendButton({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(userId));

    return statusAsync.when(
      loading: () => const SizedBox(
        height: 36,
        width: 120,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) => _FriendButton(userId: userId, status: status),
    );
  }
}

class _FriendButton extends ConsumerWidget {
  const _FriendButton({required this.userId, required this.status});

  final String userId;
  final FriendshipStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(friendRequestNotifierProvider.notifier);
    final isLoading = ref.watch(
      friendRequestNotifierProvider.select((s) => s.isLoading),
    );

    Future<void> showError(String msg) async {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    switch (status) {
      case FriendshipStatus.none:
        return FilledButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  final err = await notifier.sendRequest(userId);
                  if (err != null) showError(err);
                },
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add Friend'),
          style: FilledButton.styleFrom(
            backgroundColor: SpontiColors.primary,
            foregroundColor: SpontiColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

      case FriendshipStatus.pendingSent:
        return OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  // Need request ID — fetch via status lookup then cancel.
                  final repo = ref.read(friendsRepositoryProvider);
                  final result = await repo.getRequestBetween(userId);
                  final requestId = result.fold((_) => null, (r) => r?.id);
                  if (requestId == null) return;
                  final err = await notifier.cancelRequest(requestId, userId);
                  if (err != null) showError(err);
                },
          icon: const Icon(Icons.hourglass_top_rounded, size: 16),
          label: const Text('Request Sent'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SpontiColors.textSecondary,
            side: const BorderSide(color: SpontiColors.outline),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

      case FriendshipStatus.pendingReceived:
        return _AcceptDeclineButtons(userId: userId);

      case FriendshipStatus.friends:
        return OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  final confirm = await _confirmRemove(context);
                  if (!confirm) return;
                  final err = await notifier.removeFriend(userId);
                  if (err != null) showError(err);
                },
          icon: const Icon(Icons.person_remove_rounded, size: 16),
          label: const Text('Friends'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SpontiColors.secondary,
            side: const BorderSide(color: SpontiColors.secondary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
    }
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove Friend'),
            content: const Text('Are you sure you want to remove this friend?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: SpontiColors.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _AcceptDeclineButtons extends ConsumerWidget {
  const _AcceptDeclineButtons({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(friendRequestNotifierProvider.notifier);
    final isLoading = ref.watch(
      friendRequestNotifierProvider.select((s) => s.isLoading),
    );
    final incoming = ref.watch(incomingRequestsProvider).valueOrNull;
    final request = incoming?.where((r) => r.senderId == userId).firstOrNull;

    if (request == null) return const SizedBox.shrink();

    Future<void> showError(String msg) async {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: isLoading
              ? null
              : () async {
                  final err = await notifier.acceptRequest(request.id, userId);
                  if (err != null) showError(err);
                },
          style: FilledButton.styleFrom(
            backgroundColor: SpontiColors.primary,
            foregroundColor: SpontiColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Accept'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: isLoading
              ? null
              : () async {
                  final err = await notifier.declineRequest(request.id, userId);
                  if (err != null) showError(err);
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: SpontiColors.textSecondary,
            side: const BorderSide(color: SpontiColors.outline),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Decline'),
        ),
      ],
    );
  }
}
