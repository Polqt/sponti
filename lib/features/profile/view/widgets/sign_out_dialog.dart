import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:sponti/features/profile/viewmodel/profile_viewmodel.dart';

/// Shows a confirmation dialog and handles sign out.
Future<void> showSignOutDialog(BuildContext context, WidgetRef ref) async {
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: SpontiColors.error),
              ),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed || !context.mounted) return;

  final signedOut = await ref.read(authProvider.notifier).signOut();
  if (!context.mounted) return;

  if (!signedOut) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign out failed. Please try again.')),
    );
    return;
  }

  ref.invalidate(authProvider);
  ref.invalidate(profileProvider);
  context.go(RouteName.signin);
}
