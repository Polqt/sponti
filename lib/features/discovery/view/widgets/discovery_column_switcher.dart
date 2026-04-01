import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/discovery/viewmodel/discovery_viewmodel.dart';

/// iOS 2025-style segmented control for Discovery screen tabs.
class DiscoveryColumnSwitcher extends StatelessWidget {
  const DiscoveryColumnSwitcher({
    super.key,
    required this.activeColumn,
    required this.onChanged,
  });

  final DiscoveryColumn activeColumn;
  final ValueChanged<DiscoveryColumn> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SpontiColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentTab(
            label: 'For You',
            isSelected: activeColumn == DiscoveryColumn.forYou,
            onTap: () => onChanged(DiscoveryColumn.forYou),
          ),
          _SegmentTab(
            label: 'Friends',
            isSelected: activeColumn == DiscoveryColumn.friends,
            onTap: () => onChanged(DiscoveryColumn.friends),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatefulWidget {
  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SegmentTab> createState() => _SegmentTabState();
}

class _SegmentTabState extends State<_SegmentTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected ? SpontiColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: SpontiColors.shadow.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected
                  ? SpontiColors.textPrimary
                  : SpontiColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
