import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/utils/helpers.dart';
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/sponti.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Discover Bacolod, spontaneously.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3F4348),
                          fontSize: 18,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 10),
                      const Text(
                        'or',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF4D4D4D),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: TermsFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
    logoWidget: SvgPicture.asset(
      'assets/icons/google.svg',
      width: 20,
      height: 20,
    ),
    backgroundColor: Colors.white,
    textColor: const Color(0xFF1D1D1D),
    borderColor: const Color(0xFFE1E1E1),
    onTap: onTap,
    isLoading: isLoading,
  );

  factory _OAuthButton.facebook({
    required VoidCallback onTap,
    required bool isLoading,
  }) => _OAuthButton(
    label: 'Continue with Facebook',
    logoWidget: SvgPicture.asset(
      'assets/icons/facebook.svg',
      width: 22,
      height: 20,
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
      height: 46,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shadowColor: const Color(0x55000000),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
            : Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: logoWidget,
                    ),
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
