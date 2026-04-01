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
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueListenable<String> queryListenable;
  final bool isLoading;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: _SearchField(
            controller: controller,
            queryListenable: queryListenable,
            isLoading: isLoading,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onClear: onClear,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 22,
      iconSize: 22,
      color: SpontiColors.textPrimary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  const _SearchActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isEnabled ? onTap : null,
      splashRadius: 20,
      iconSize: 20,
      color: isEnabled
          ? SpontiColors.textSecondary
          : SpontiColors.textSecondary.withValues(alpha: 0.48),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(icon),
    );
  }
}

class _SearchTextFieldTheme extends StatelessWidget {
  const _SearchTextFieldTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.queryListenable,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueListenable<String> queryListenable;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: SpontiColors.textSecondary.withValues(alpha: 0.78),
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SearchTextFieldTheme(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Search spots, cafes, parks',
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SpontiColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isCollapsed: true,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SpontiColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                  cursorColor: SpontiColors.primary,
                ),
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: SpontiColors.primary,
                  ),
                ),
              ),
            ValueListenableBuilder<String>(
              valueListenable: queryListenable,
              builder: (context, value, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: value.isEmpty
                      ? _SearchActionButton(
                          key: const ValueKey('search_tune'),
                          icon: Icons.tune_rounded,
                          onTap: onClear,
                          isEnabled: false,
                        )
                      : _SearchActionButton(
                          key: const ValueKey('search_clear'),
                          icon: Icons.close_rounded,
                          onTap: onClear,
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
