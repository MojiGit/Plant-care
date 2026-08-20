import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/plant.dart';
import '../../data/plant_repository.dart';
import '../../ui/app_theme.dart';
import '../add_plant/add_plant_flow.dart';
import '../plant_detail/plant_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../today/today_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = PlantRepository();
  int _navIndex = 0;
  List<Plant> _plants = [];
  Map<int, DateTime> _nextDue = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await _repo.getPlants();
      final nextDue = await _repo.getNextDueDates();
      if (mounted) setState(() { _plants = plants; _nextDue = nextDue; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddPlant() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddPlantFlow()),
    );
    _loadPlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monstera')),
      body: _navIndex == 2
          ? const ProfileScreen()
          : _navIndex == 1
          ? const TodayScreen()
          : _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
              : _plants.isEmpty
                  ? _EmptyState(onAddPlant: _openAddPlant)
                  : _PlantList(plants: _plants, nextDue: _nextDue, onAddPlant: _openAddPlant, onRefresh: _loadPlants),
      floatingActionButton: (_navIndex != 0 || _plants.isEmpty)
          ? null
          : FloatingActionButton(
              onPressed: _openAddPlant,
              tooltip: 'Añadir planta',
              child: const Icon(Icons.document_scanner_outlined, size: 24),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() { _navIndex = i; if (i == 0) _loading = true; });
          if (i == 0) _loadPlants();
        },
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

// ── Lista de plantas ──────────────────────────────────────────────────────────

class _PlantList extends StatelessWidget {
  final List<Plant> plants;
  final Map<int, DateTime> nextDue;
  final VoidCallback onAddPlant;
  final VoidCallback onRefresh;
  const _PlantList({required this.plants, required this.nextDue, required this.onAddPlant, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Tu colección',
              style: GoogleFonts.caprasimo(fontSize: 22, color: AppTheme.dark),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PlantCard(
                    plant: plants[i],
                    nextDueAt: nextDue[plants[i].id],
                    onNeedRefresh: onRefresh,
                  ),
              childCount: plants.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  final DateTime? nextDueAt;
  final VoidCallback onNeedRefresh;
  const _PlantCard({required this.plant, this.nextDueAt, required this.onNeedRefresh});

  String get _lightLabel => switch (plant.lightNeed) {
        'low'    => 'Poca luz',
        'direct' => 'Luz directa',
        _        => 'Luz indirecta',
      };

  ({String label, Color color}) get _dueInfo {
    if (nextDueAt == null) return (label: 'Sin programar', color: AppTheme.muted);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due   = DateTime(nextDueAt!.year, nextDueAt!.month, nextDueAt!.day);
    final diff  = due.difference(today).inDays;
    if (diff < 0)  return (label: 'Vencida',      color: AppTheme.terracotta);
    if (diff == 0) return (label: 'Hoy',           color: AppTheme.amber);
    if (diff == 1) return (label: 'Mañana',        color: AppTheme.sage);
    return           (label: 'En $diff días',      color: AppTheme.sage);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)))
          .then((_) => onNeedRefresh()),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.sageTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.eco_rounded, color: AppTheme.sage, size: 26),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.displayName,
                    style: GoogleFonts.caprasimo(fontSize: 16, color: AppTheme.dark),
                  ),
                  if (plant.displaySubtitle != null)
                    Text(
                      plant.displaySubtitle!,
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: AppTheme.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (plant.family != null)
                    Text(
                      plant.family!,
                      style: GoogleFonts.figtree(fontSize: 11, color: AppTheme.muted),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Tag(label: _lightLabel),
                      _Tag(label: _dueInfo.label, color: _dueInfo.color),
                      if (plant.edibleParts.isNotEmpty)
                        _Tag(label: 'Comestible', color: AppTheme.amber),
                      if (plant.isToxic)
                        _Tag(label: 'Tóxica', color: AppTheme.terracotta),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, this.color = AppTheme.sage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: GoogleFonts.figtree(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

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
