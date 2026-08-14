import 'package:flutter/material.dart';

class IdentificationScreen extends StatelessWidget {
  const IdentificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identify Plant')),
      body: const Center(child: Text('Plant identification — coming soon')),
    );
  }
}
