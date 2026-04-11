import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/core/theme/app_colors.dart';
import 'package:sponti/features/suggestions/model/suggestion_model.dart';
import 'package:sponti/features/suggestions/view/map_picker_screen.dart';
import 'package:sponti/features/suggestions/view/widgets/category_picker.dart';
import 'package:sponti/features/suggestions/view/widgets/map_pin_row.dart';
import 'package:sponti/features/suggestions/view/widgets/success_sheet.dart';
import 'package:sponti/features/suggestions/viewmodel/suggestions_viewmodel.dart';

const _pageBackground = SpontiColors.surface;
const _cardBorder = Color(0xFFDDDDDD);
const _textPrimary = Color(0xFF111111);
const _textMuted = Color(0xFF7A7A7A);

class SuggestSpotScreen extends ConsumerStatefulWidget {
  const SuggestSpotScreen({super.key});

  @override
  ConsumerState<SuggestSpotScreen> createState() => _SuggestSpotScreenState();
}

class _SuggestSpotScreenState extends ConsumerState<SuggestSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  SpotCategory? _selectedCategory;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(submitSuggestionProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          _showSuccessSheet();
          _clearForm();
        },
        error: (e, _) => _showErrorSnackbar(e.toString()),
      );
    });

    final submitState = ref.watch(submitSuggestionProvider);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggest a spot',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share a hidden gem with the community.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SpontiColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _SuggestionForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    descriptionController: _descriptionController,
                    addressController: _addressController,
                    selectedCategory: _selectedCategory,
                    latitude: _latitude,
                    longitude: _longitude,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    onMapPinTap: _openMapPicker,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SubmitButton(
                isLoading: submitState.isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 10),
              _CancelButton(
                onPressed: submitState.isLoading
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('please choose a category')));
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop a map pin so your spot appears on the map.'),
        ),
      );
      return;
    }

    final suggestion = SuggestionModel(
      id: '',
      userId: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory!.label,
      address: _addressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      createdAt: DateTime.now(),
    );

    await ref.read(submitSuggestionProvider.notifier).submit(suggestion);
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MapPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.coordinates.latitude;
        _longitude = result.coordinates.longitude;
      });
    }
  }

  Future<void> _showSuccessSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SuccessSheet(),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE24B4A),
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _addressController.clear();

    setState(() {
      _selectedCategory = null;
      _latitude = null;
      _longitude = null;
    });
  }
}

class _SuggestionForm extends StatelessWidget {
  const _SuggestionForm({
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.addressController,
    required this.selectedCategory,
    required this.latitude,
    required this.longitude,
    required this.onCategorySelected,
    required this.onMapPinTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController addressController;
  final SpotCategory? selectedCategory;
  final double? latitude;
  final double? longitude;
  final ValueChanged<SpotCategory> onCategorySelected;
  final VoidCallback onMapPinTap;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('spot name'),
          const SizedBox(height: 8),
          _LabeledField(
            controller: nameController,
            hintText: 'enter spot name',
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'spot name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('category'),
          const SizedBox(height: 8),
          CategoryPicker(
            selected: selectedCategory,
            onSelected: onCategorySelected,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('description (optional)'),
          const SizedBox(height: 8),
          _LabeledField(
            controller: descriptionController,
            hintText: 'tell us more about this spot',
            maxLines: 4,
            dashedBorder: true,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('address'),
          const SizedBox(height: 8),
          _LabeledField(
            controller: addressController,
            hintText: 'enter full address',
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('map pin (required)'),
          const SizedBox(height: 8),
          _DashedContainer(
            child: MapPinRow(
              latitude: latitude,
              longitude: longitude,
              onTap: onMapPinTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: _textMuted,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.maxLines = 1,
    this.dashedBorder = false,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool dashedBorder;

  @override
  Widget build(BuildContext context) {
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _cardBorder, width: 0.5),
    );

    final textField = TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: _textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: dashedBorder ? InputBorder.none : normalBorder,
        enabledBorder: dashedBorder ? InputBorder.none : normalBorder,
        focusedBorder: dashedBorder
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _textPrimary, width: 1),
              ),
        errorBorder: dashedBorder
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFC53030),
                  width: 0.8,
                ),
              ),
      ),
    );

    if (!dashedBorder) {
      return textField;
    }

    return _DashedContainer(child: textField);
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          shape: const StadiumBorder(),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'submit suggestion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: _cardBorder, width: 0.5),
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        child: const Text(
          'cancel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DashedContainer extends StatelessWidget {
  const _DashedContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = 12.0;
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
          paint,
        );
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
