import 'package:flutter/material.dart';
import 'package:sponti/core/theme/app_colors.dart';

enum _DiscoverColumn { forYou, friends }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _topPicks = [
    _DiscoverCardData(
      title: 'Trending',
      subtitle: 'they keep coming back',
      chipColor: Color(0xFFD4458C),
      placeholderColors: [Color(0xFFF5E5DC), Color(0xFFD7B89A)],
      icon: Icons.local_fire_department_rounded,
    ),
    _DiscoverCardData(
      title: 'Lowkey',
      subtitle: 'spots unknown to some',
      chipColor: SpontiColors.info,
      placeholderColors: [Color(0xFFF6F1EB), Color(0xFFD7ECE9)],
      icon: Icons.visibility_off_rounded,
    ),
    _DiscoverCardData(
      title: 'Popular',
      subtitle: 'people love these spots!',
      chipColor: Color(0xFFE07A15),
      placeholderColors: [Color(0xFF321033), Color(0xFF6D235C)],
      icon: Icons.favorite_rounded,
    ),
    _DiscoverCardData(
      title: 'New',
      subtitle: 'be their first customer!',
      chipColor: SpontiColors.success,
      placeholderColors: [Color(0xFF20342A), Color(0xFF4E8E63)],
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  _DiscoverColumn _activeColumn = _DiscoverColumn.forYou;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionTitle = _activeColumn == _DiscoverColumn.forYou
        ? 'TOP PICKS'
        : 'FRIENDS';

    return Scaffold(
      backgroundColor: SpontiColors.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _DiscoverColumnSwitcher(
                  activeColumn: _activeColumn,
                  onChanged: (column) {
                    setState(() => _activeColumn = column);
                  },
                ),
              ),
              const SizedBox(height: 30),
              Text(
                sectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _activeColumn == _DiscoverColumn.forYou
                    ? const _ForYouGrid(cards: _topPicks)
                    : const _FriendsComingSoon(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverColumnSwitcher extends StatelessWidget {
  const _DiscoverColumnSwitcher({
    required this.activeColumn,
    required this.onChanged,
  });

  final _DiscoverColumn activeColumn;
  final ValueChanged<_DiscoverColumn> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DiscoverColumnTab(
            label: 'for you',
            isSelected: activeColumn == _DiscoverColumn.forYou,
            onTap: () => onChanged(_DiscoverColumn.forYou),
          ),
          const SizedBox(width: 20),
          _DiscoverColumnTab(
            label: 'friends',
            isSelected: activeColumn == _DiscoverColumn.friends,
            onTap: () => onChanged(_DiscoverColumn.friends),
          ),
        ],
      ),
    );
  }
}

class _DiscoverColumnTab extends StatelessWidget {
  const _DiscoverColumnTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: isSelected
          ? SpontiColors.textPrimary
          : SpontiColors.textSecondary,
      letterSpacing: -0.2,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textStyle),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 2,
              width: isSelected ? 54 : 0,
              decoration: BoxDecoration(
                color: SpontiColors.textPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForYouGrid extends StatelessWidget {
  const _ForYouGrid({required this.cards});

  final List<_DiscoverCardData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('for-you-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        mainAxisExtent: 262,
      ),
      itemBuilder: (context, index) => _DiscoverTopPickCard(card: cards[index]),
    );
  }
}

class _DiscoverTopPickCard extends StatelessWidget {
  const _DiscoverTopPickCard({required this.card});

  final _DiscoverCardData card;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('${card.title} picks are coming soon.')),
            );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF4EFF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SpontiColors.outline),
            boxShadow: [
              BoxShadow(
                color: SpontiColors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: _CardImagePlaceholder(card: card),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: card.chipColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: card.chipColor.withValues(alpha: 0.34),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            card.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SpontiColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImagePlaceholder extends StatelessWidget {
  const _CardImagePlaceholder({required this.card});

  final _DiscoverCardData card;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: card.placeholderColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 18,
                color: SpontiColors.textSecondary,
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: -8,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    card.icon,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsComingSoon extends StatelessWidget {
  const _FriendsComingSoon();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('friends-coming-soon'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SpontiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SpontiColors.outline),
        boxShadow: [
          BoxShadow(
            color: SpontiColors.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SpontiColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: SpontiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Friends picks are coming soon',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are preparing a shared feed where you can browse places your friends are into, save their picks, and compare vibes in one scroll.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SpontiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverCardData {
  const _DiscoverCardData({
    required this.title,
    required this.subtitle,
    required this.chipColor,
    required this.placeholderColors,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color chipColor;
  final List<Color> placeholderColors;
  final IconData icon;
}
