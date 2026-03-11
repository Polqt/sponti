import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

/// Displayed when an async operation fails.
///
/// ```dart
/// AppErrorState(
///   message: error.toString(),
///   onRetry: () => ref.invalidate(locationsProvider),
/// )
/// ```
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SpontiColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: SpontiColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SpontiColors.error,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Async State Builder

/// Wraps a [AsyncValue] and renders loading, error, and data states
// in a consistent way. Reduces boilerplate in every screen.
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.value,
    required this.loading,
    required this.error,
    required this.data,
  });

  // Using dynamic to avoid importing flutter_riverpod in the widget layer.
  // The caller casts and passes the right closures.
  final dynamic value; // AsyncValue<T>
  final Widget Function() loading;
  final Widget Function(String message) error;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    // Delegate to the caller's .when() — this widget just enforces
    // a consistent structure without coupling to Riverpod.
    return value.when(
      loading: loading,
      error: (e, _) => error(e.toString()),
      data: data,
    );
  }
}
