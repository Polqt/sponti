import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/view/widgets/category.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class VoteCard extends ConsumerWidget {
  const VoteCard({
    required this.locationId,
    required this.voteCount,
    required this.totalVotes,
    required this.isUserVote,
    required this.isWinner,
    required this.isVotingEnabled,
    this.onVote,
    super.key,
  });

  final String locationId;
  final int voteCount;
  final int totalVotes;
  final bool isUserVote;
  final bool isWinner;
  final bool isVotingEnabled;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationDetailProvider(locationId));
    final location = locationAsync.valueOrNull;
    final locationName = location?.name ?? '...';

    final ratio = totalVotes > 0 ? voteCount / totalVotes : 0.0;
    final barColor = isWinner
        ? SpontiColors.success
        : isUserVote
            ? SpontiColors.primary
            : SpontiColors.outline;
    final bgColor = isWinner
        ? SpontiColors.success.withValues(alpha: 0.06)
        : isUserVote
            ? SpontiColors.primary.withValues(alpha: 0.05)
            : Colors.white;
    final borderColor = isWinner
        ? SpontiColors.success.withValues(alpha: 0.4)
        : isUserVote
            ? SpontiColors.primary.withValues(alpha: 0.3)
            : SpontiColors.outline.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isVotingEnabled ? onVote : null,
          splashColor: SpontiColors.primary.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: location != null
                              ? location.hasPhotos
                                  ? _NetworkThumb(
                                      url: location.primaryPhoto,
                                      category: location.category,
                                    )
                                  : CategoryGradient(category: location.category)
                              : Container(color: SpontiColors.surfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationName,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SpontiColors.textPrimary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$voteCount vote${voteCount == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SpontiColors.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isWinner)
                        _Badge(
                          label: 'Leading',
                          bg: SpontiColors.success.withValues(alpha: 0.12),
                          fg: SpontiColors.success,
                        )
                      else if (isUserVote)
                        _Badge(
                          label: 'Voted',
                          bg: SpontiColors.primary.withValues(alpha: 0.10),
                          fg: SpontiColors.primary,
                        )
                      else
                        _VoteOrb(count: voteCount),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: SpontiColors.outline.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
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

class _NetworkThumb extends StatelessWidget {
  const _NetworkThumb({required this.url, required this.category});

  final String url;
  final LocationCategory category;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => CategoryGradient(category: category),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _VoteOrb extends StatelessWidget {
  const _VoteOrb({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: SpontiColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: SpontiColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
