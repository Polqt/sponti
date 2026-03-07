import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart' show SpontiColors;

class TermsFooter extends StatelessWidget {
  const TermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final linkStyle =
        style?.copyWith(color: SpontiColors.primary, decoration: TextDecoration.underline);
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: style,
        children: [
          TextSpan(text: 'Terms of Service', style: linkStyle),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: linkStyle),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}