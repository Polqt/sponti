import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/core/widgets/glass_container.dart';

class LocationMapSearchBar extends StatelessWidget {
  const LocationMapSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(RouteName.search),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            blurSigma: 16,
            opacity: 0.65,
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: SpontiColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search spots, cafes, parks',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SpontiColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: SpontiColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
