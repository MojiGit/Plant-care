import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/app_theme.dart';
import '../add_plant/add_plant_flow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  Future<void> _openAddPlant() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPlantFlow()),
    );
    setState(() {}); // PC403: refrescará la lista real
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monstera')),
      body: _EmptyState(onAddPlant: _openAddPlant),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPlant,
        tooltip: 'Añadir planta',
        child: const Icon(Icons.document_scanner_outlined, size: 24),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Colección',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPlant;
  const _EmptyState({required this.onAddPlant});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.eco_rounded, size: 56, color: AppTheme.sage),
            const SizedBox(height: 24),
            Text(
              'Tu colección\nestá vacía',
              style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Escanea tu primera planta para empezar a cuidarla.',
              style: GoogleFonts.figtree(fontSize: 15, color: AppTheme.muted, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddPlant,
              icon: const Icon(Icons.document_scanner_outlined, size: 18),
              label: const Text('Escanear planta'),
            ),
          ],
        ),
      ),
    );
  }
}
