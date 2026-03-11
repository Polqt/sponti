import 'package:flutter/material.dart';

class LocationDetailScreen extends StatelessWidget {
  const LocationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot Details')),
      body: Center(child: Text('Location detail for ID: $id')),
    );
  }
}
