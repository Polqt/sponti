import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/locations/viewmodel/location_viewmodel.dart';

class SurpriseMeModal extends ConsumerStatefulWidget {
  const SurpriseMeModal({super.key});

  @override
  ConsumerState<SurpriseMeModal> createState() => _SurpriseMeModalState();
}

class _SurpriseMeModalState extends ConsumerState<SurpriseMeModal> {
  late Set<LocationCategory> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {};
  }

  @override
  void dispose() {
    // Reset the surprise me provider when modal is dismissed
    ref.read(surpriseMeProvider.notifier).reset();
    super.dispose();
  }

  void _toggleCategory(LocationCategory category) {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  void _onSurpriseMe() {
    final categories = _selected.map((c) => c.name).toList();
    ref.read(surpriseMeProvider.notifier).pickRandom(categories);
  }

  void _onAnyCategory() {
    ref.read(surpriseMeProvider.notifier).pickRandom([]);
  }

  @override
  Widget build(BuildContext context) {
    final surpriseMeState = ref.watch(surpriseMeProvider);

    ref.listen<AsyncValue<Location?>>(surpriseMeProvider, (_, next) {
      next.whenOrNull(
        data: (location) {
          if (location != null) {
            Navigator.pop(context);
            context.push(RouteName.locationDetailPath(location.id));
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Drag handle pill
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Subtitle
                Text(
                  'feeling spontaneous?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                const Text(
                  'what are you in the mood for?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  'pick one or more — we\'ll find something great.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                // Category grid
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: LocationCategory.values.map((category) {
                    final isSelected = _selected.contains(category);
                    return CategoryChip(
                      category: category,
                      isSelected: isSelected,
                      onTap: () => _toggleCategory(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Primary button
                _buildPrimaryButton(surpriseMeState),
                const SizedBox(height: 12),

                // Secondary button
                _buildSecondaryButton(surpriseMeState),
                const SizedBox(height: 20),

                // Error message
                if (surpriseMeState is AsyncError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      surpriseMeState.error.toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(AsyncValue<Location?> state) {
    final isLoading = state is AsyncLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onSurpriseMe,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2979FF),
          disabledBackgroundColor: const Color(0xFF2979FF).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              )
            : const Text(
                'surprise me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(AsyncValue<Location?> state) {
    final isLoading = state is AsyncLoading;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : _onAnyCategory,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          disabledForegroundColor: Colors.white.withOpacity(0.5),
        ),
        child: const Text(
          'any category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final LocationCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
