import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

class SearchTopBar extends StatelessWidget {
  const SearchTopBar({
    super.key,
    required this.controller,
    required this.queryListenable,
    required this.isLoading,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueListenable<String> queryListenable;
  final bool isLoading;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _FrostButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FrostSearchField(
                  controller: controller,
                  queryListenable: queryListenable,
                  isLoading: isLoading,
                  onChanged: onChanged,
                  onClear: onClear,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Search',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: SpontiColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find cafes, parks, and low-key gems nearby.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostButton extends StatelessWidget {
  const _FrostButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.white.withValues(alpha: 0.58),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SpontiColors.shadow.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: SpontiColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostSearchField extends StatelessWidget {
  const _FrostSearchField({
    required this.controller,
    required this.queryListenable,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueListenable<String> queryListenable;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.035),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: SpontiColors.textSecondary.withValues(alpha: 0.85),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search spots, cafes, parks',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SpontiColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  cursorColor: SpontiColors.primary,
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: SpontiColors.primary,
                    ),
                  ),
                ),
              ValueListenableBuilder<String>(
                valueListenable: queryListenable,
                builder: (context, value, _) {
                  if (value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: SpontiColors.textPrimary.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: SpontiColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
