import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/utils/helpers.dart';
import 'package:sponti/features/auth/view/widgets/header.dart';
import 'package:sponti/features/auth/view/widgets/terms_footer.dart';
import 'package:sponti/features/auth/viewmodel/auth_viewmodel.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.valueOrNull != null) context.go(RouteName.location);
    });

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Header(),
              const Spacer(flex: 3),
              _OAuthButton.google(
                isLoading: authAsync.isLoading,
                onTap: () async {
                  final success = await ref
                      .read(authProvider.notifier)
                      .signInWithGoogle();
                  if (!success && context.mounted) {
                    final error = ref.read(authProvider).error;
                    SpontiSnackBar.error(
                      context,
                      error?.toString() ?? 'Google sign-in failed',
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              _OAuthButton.facebook(
                isLoading: authAsync.isLoading,
                onTap: () async {
                  final success = await ref
                      .read(authProvider.notifier)
                      .signInWithFacebook();
                  if (!success && context.mounted) {
                    final error = ref.read(authProvider).error;
                    SpontiSnackBar.error(
                      context,
                      error?.toString() ?? 'Facebook sign-in failed',
                    );
                  }
                },
              ),
              const Spacer(),
              const TermsFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.logoWidget,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
    required this.isLoading,
  });

  factory _OAuthButton.google({
    required VoidCallback onTap,
    required bool isLoading,
  }) => _OAuthButton(
    label: 'Continue with Google',
    logoWidget: Image.network(
      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
      width: 22,
      height: 22,
      errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, size: 24),
    ),
    backgroundColor: Colors.white,
    textColor: SpontiColors.textPrimary,
    borderColor: SpontiColors.outline,
    onTap: onTap,
    isLoading: isLoading,
  );

  factory _OAuthButton.facebook({
    required VoidCallback onTap,
    required bool isLoading,
  }) => _OAuthButton(
    label: 'Continue with Facebook',
    logoWidget: const Icon(
      Icons.facebook_rounded,
      color: Colors.white,
      size: 22,
    ),
    backgroundColor: const Color(0xFF1877F2),
    textColor: Colors.white,
    borderColor: Colors.transparent,
    onTap: onTap,
    isLoading: isLoading,
  );

  final String label;
  final Widget logoWidget;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logoWidget,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
