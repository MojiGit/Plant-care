import 'package:flutter/material.dart';

class CareScreen extends StatelessWidget {
  final String plantId;
  const CareScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Care Plan')),
      body: Center(child: Text('Care plan for plant $plantId — coming soon')),
    );
  }
}
