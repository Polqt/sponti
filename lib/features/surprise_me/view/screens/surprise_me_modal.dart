import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sponti/config/routes/route_name.dart';
import 'package:sponti/features/locations/model/location.dart';
import 'package:sponti/features/surprise_me/view/widgets/surprise_me_actions.dart';
import 'package:sponti/features/surprise_me/view/widgets/surprise_me_category_grid.dart';
import 'package:sponti/features/surprise_me/view/widgets/surprise_me_modal_scaffold.dart';
import 'package:sponti/features/surprise_me/viewmodel/surprise_me_viewmodel.dart';

class SurpriseMeModal extends ConsumerStatefulWidget {
  const SurpriseMeModal({super.key});

  @override
  ConsumerState<SurpriseMeModal> createState() => _SurpriseMeModalState();
}

class _SurpriseMeModalState extends ConsumerState<SurpriseMeModal> {
  late final ProviderSubscription<AsyncValue<Location?>> _subscription;
  Set<LocationCategory> _selectedCategories = <LocationCategory>{};

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AsyncValue<Location?>>(
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
    _subscription.close();
    super.dispose();
  }

  void _toggleCategory(LocationCategory category) {
    final updatedCategories = Set<LocationCategory>.of(_selectedCategories);
    if (!updatedCategories.add(category)) {
      updatedCategories.remove(category);
    }

    setState(() => _selectedCategories = updatedCategories);
  }

  void _pickSelectedCategories() {
    ref.read(surpriseMeProvider.notifier).pickRandom(
          _selectedCategories.map((category) => category.name).toList(),
        );
  }

  void _pickAnyCategory() {
    ref.read(surpriseMeProvider.notifier).pickRandom(const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final surpriseState = ref.watch(surpriseMeProvider);
    final isLoading = surpriseState is AsyncLoading;
    final errorText = surpriseState.hasError
        ? surpriseState.error.toString()
        : null;

    return SurpriseMeModalScaffold(
      child: Column(
        children: [
          const SurpriseMeCloseRow(),
          const SizedBox(height: 12),
          const SurpriseMeDragHandle(),
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
            'pick one or more and we will find something great.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 28),
          SurpriseMeCategoryGrid(
            selectedCategories: _selectedCategories,
            onCategoryTapped: _toggleCategory,
          ),
          const SizedBox(height: 32),
          SurprisePrimaryButton(
            isLoading: isLoading,
            onPressed: _pickSelectedCategories,
          ),
          const SizedBox(height: 12),
          SurpriseAnyCategoryButton(
            isLoading: isLoading,
            onPressed: _pickAnyCategory,
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
    );
  }
}
