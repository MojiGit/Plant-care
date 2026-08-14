import 'package:flutter/material.dart';

class PlantCollectionScreen extends StatelessWidget {
  const PlantCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Plants')),
      body: const Center(child: Text('Plant collection — coming soon')),
    );
  }
}
