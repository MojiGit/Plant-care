import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/plant_repository.dart';
import '../../domain/gamification_engine.dart';
import '../../ui/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = PlantRepository();
  Map<String, dynamic>? _stats;
  int _plantCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _repo.getUserStats();
    final plants = await _repo.getPlants();
    if (mounted) setState(() { _stats = stats; _plantCount = plants.length; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.sage));

    final points = _stats!['points'] as int;
    final level  = GamificationEngine.levelFor(points);
    final toNext = GamificationEngine.pointsToNextLevel(points);

    final levelLabel = switch (level) {
      Level.seedling       => 'Seedling',
      Level.gardener       => 'Gardener',
      Level.botanist       => 'Botanist',
      Level.masterBotanist => 'Master Botanist',
    };

    final levelThresholds = {
      Level.seedling:       0,
      Level.gardener:       150,
      Level.botanist:       500,
      Level.masterBotanist: 1500,
    };

    final currentThreshold = levelThresholds[level]!;
    final nextThreshold = toNext != null ? points + toNext : points;
    final progress = toNext != null
        ? (points - currentThreshold) / (nextThreshold - currentThreshold)
        : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perfil', style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark)),
          const SizedBox(height: 24),

          // ── Nivel + puntos ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.dark.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.sage,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(levelLabel,
                          style: GoogleFonts.caprasimo(fontSize: 14, color: AppTheme.cream)),
                    ),
                    const Spacer(),
                    Text('$points pts',
                        style: GoogleFonts.caprasimo(fontSize: 22, color: AppTheme.dark)),
                  ],
                ),
                const SizedBox(height: 16),
                if (toNext != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppTheme.sageTint,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sage),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$toNext pts para el siguiente nivel',
                      style: GoogleFonts.figtree(fontSize: 12, color: AppTheme.muted)),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 8,
                      backgroundColor: AppTheme.sageTint,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.amber),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Nivel máximo alcanzado',
                      style: GoogleFonts.figtree(fontSize: 12, color: AppTheme.amber, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats ──
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Plantas', value: '$_plantCount')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Puntos', value: '$points')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Racha', value: '${_stats!['streak_days']}d')),
            ],
          ),
          const SizedBox(height: 24),

          // ── Cómo ganar puntos ──
          Text('Cómo ganar puntos',
              style: GoogleFonts.caprasimo(fontSize: 16, color: AppTheme.dark)),
          const SizedBox(height: 12),
          _PointRow(icon: Icons.document_scanner_outlined, label: 'Registrar una planta nueva', pts: 50),
          _PointRow(icon: Icons.water_drop_outlined,       label: 'Regar una planta',           pts: 3),
          _PointRow(icon: Icons.check_outlined,            label: 'Revisar la tierra',           pts: 1),
          const SizedBox(height: 24),

          // ── Niveles ──
          Text('Niveles', style: GoogleFonts.caprasimo(fontSize: 16, color: AppTheme.dark)),
          const SizedBox(height: 12),
          _LevelRow(name: 'Seedling',       pts: 0,    current: level == Level.seedling),
          _LevelRow(name: 'Gardener',       pts: 150,  current: level == Level.gardener),
          _LevelRow(name: 'Botanist',       pts: 500,  current: level == Level.botanist),
          _LevelRow(name: 'Master Botanist',pts: 1500, current: level == Level.masterBotanist),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D8CC)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.caprasimo(fontSize: 22, color: AppTheme.dark)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.figtree(fontSize: 12, color: AppTheme.muted)),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int pts;
  const _PointRow({required this.icon, required this.label, required this.pts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.sage),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.dark))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.amber.withAlpha(25),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.amber.withAlpha(60)),
            ),
            child: Text('+$pts pts',
                style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.amber)),
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String name;
  final int pts;
  final bool current;
  const _LevelRow({required this.name, required this.pts, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: current ? AppTheme.sageTint : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: current ? AppTheme.sage : const Color(0xFFE0D8CC)),
      ),
      child: Row(
        children: [
          Text(name,
              style: GoogleFonts.figtree(
                fontSize: 14,
                fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                color: current ? AppTheme.sage : AppTheme.dark,
              )),
          const Spacer(),
          Text('$pts pts',
              style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.muted)),
          if (current) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.sage),
          ],
        ],
      ),
    );
  }
}
