import 'package:flutter/material.dart';

class SurpriseScreen extends StatelessWidget {
  const SurpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surprise Me!')),
      body: const Center(child: Text('Surprise coming soon')),
    );
  }
}
