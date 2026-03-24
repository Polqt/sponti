import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponti/features/surprise_me/viewmodel/surprise_me_viewmodel.dart';

class SurpriseMeModal extends ConsumerWidget {
  const SurpriseMeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surpriseState = ref.watch(surpriseMeProvider);

    final message = switch (surpriseState) {
      AsyncData(value: final location?) => 'Try ${location.name}',
      AsyncError(:final error) => error.toString(),
      _ => 'Surprise coming soon',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Surprise Me!')),
      body: Center(child: Text(message)),
    );
  }
}
