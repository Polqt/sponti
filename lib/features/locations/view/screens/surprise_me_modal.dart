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
  static const Color _backgroundColor = Color(0xFF111113);

  late final ProviderSubscription<AsyncValue<Location?>>
      _surpriseMeSubscription;
  Set<LocationCategory> _selected = <LocationCategory>{};

  @override
  void initState() {
    super.initState();
    _surpriseMeSubscription = ref.listenManual<AsyncValue<Location?>>(
      surpriseMeProvider,
      (_, next) {
        next.whenOrNull(
          data: (location) {
            if (!mounted || location == null) return;
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            Future<void>(
              () => router.push(RouteName.locationDetailPath(location.id)),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _surpriseMeSubscription.close();
    super.dispose();
  }

  void _toggleCategory(LocationCategory category) {
    final updated = Set<LocationCategory>.of(_selected);
    if (!updated.add(category)) {
      updated.remove(category);
    }
    setState(() => _selected = updated);
  }

  void _pickFromSelectedCategories() {
    final categories = _selected.map((category) => category.name).toList();
    ref.read(surpriseMeProvider.notifier).pickRandom(categories);
  }

  void _pickFromAnyCategory() {
    ref.read(surpriseMeProvider.notifier).pickRandom(const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final surpriseMeState = ref.watch(surpriseMeProvider);
    final isLoading = surpriseMeState is AsyncLoading;
    final errorText = surpriseMeState.hasError
        ? surpriseMeState.error.toString()
        : null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const _CloseRow(),
                const SizedBox(height: 12),
                const _DragHandle(),
                const SizedBox(height: 24),
                Text(
                  'feeling spontaneous?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'what are you in the mood for?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'pick one or more - we\'ll find something great.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),
                GridView.builder(
                  itemCount: LocationCategory.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = LocationCategory.values[index];
                    return CategoryChip(
                      key: ValueKey(category.name),
                      category: category,
                      isSelected: _selected.contains(category),
                      onTap: () => _toggleCategory(category),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SurprisePrimaryButton(
                  isLoading: isLoading,
                  onPressed: _pickFromSelectedCategories,
                ),
                const SizedBox(height: 12),
                SurpriseAnyCategoryButton(
                  isLoading: isLoading,
                  onPressed: _pickFromAnyCategory,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    errorText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseRow extends StatelessWidget {
  const _CloseRow();

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class SurprisePrimaryButton extends StatelessWidget {
  const SurprisePrimaryButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  static const Color _primaryColor = Color(0xFF2979FF);

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.5),
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
                    Colors.white.withValues(alpha: 0.8),
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
}

class SurpriseAnyCategoryButton extends StatelessWidget {
  const SurpriseAnyCategoryButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
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
    super.key,
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
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.1),
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
