import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/plant.dart';
import '../../data/plant_repository.dart';
import '../../ui/app_theme.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final _repo = PlantRepository();
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _schedule = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _repo.getCareHistory(widget.plant.id!);
    final schedule = await _repo.getPlantSchedule(widget.plant.id!);
    if (mounted) {
      setState(() {
        _history = history;
        _schedule = schedule;
        _loading = false;
      });
    }
  }

  String get _lightLabel => switch (widget.plant.lightNeed) {
        'low'    => 'Poca luz',
        'direct' => 'Luz directa',
        _        => 'Luz indirecta',
      };

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _daysUntil(String iso) {
    final due = DateTime.parse(iso).toLocal();
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Vencido';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    return 'En $diff días';
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    return Scaffold(
      appBar: AppBar(title: Text(plant.commonName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _PlantHeader(plant: plant, lightLabel: _lightLabel),
                  const SizedBox(height: 24),

                  // ── Próximas revisiones ──
                  if (_schedule.isNotEmpty) ...[
                    _SectionTitle('Próximas revisiones'),
                    const SizedBox(height: 12),
                    ..._schedule.map((row) => _ScheduleRow(
                          taskType: row['task_type'] as String,
                          nextDueAt: row['next_due_at'] as String,
                          daysUntil: _daysUntil(row['next_due_at'] as String),
                          formatDate: _formatDate,
                        )),
                    const SizedBox(height: 24),
                  ],

                  // ── Historial ──
                  _SectionTitle('Historial de cuidados'),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    Text(
                      'Aún no hay actividad registrada.',
                      style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted),
                    )
                  else
                    ..._history.map((row) => _HistoryRow(
                          taskType: row['task_type'] as String,
                          doneAt: _formatDate(row['done_at'] as String),
                        )),
                ],
              ),
            ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PlantHeader extends StatelessWidget {
  final Plant plant;
  final String lightLabel;
  const _PlantHeader({required this.plant, required this.lightLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.sageTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.eco_rounded, color: AppTheme.sage, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.commonName,
                        style: GoogleFonts.caprasimo(fontSize: 20, color: AppTheme.dark)),
                    Text(plant.species,
                        style: GoogleFonts.figtree(
                          fontSize: 13,
                          color: AppTheme.muted,
                          fontStyle: FontStyle.italic,
                        )),
                  ],
                ),
              ),
            ],
          ),
          if (plant.isToxic) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.terracotta.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.terracotta, size: 16),
                  const SizedBox(width: 8),
                  Text('Tóxica para animales domésticos',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        color: AppTheme.terracotta,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(label: lightLabel),
              _Tag(label: 'Revisión c/${plant.wateringIntervalDays}d'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.caprasimo(fontSize: 16, color: AppTheme.dark));
  }
}

class _ScheduleRow extends StatelessWidget {
  final String taskType;
  final String nextDueAt;
  final String daysUntil;
  final String Function(String) formatDate;
  const _ScheduleRow({
    required this.taskType,
    required this.nextDueAt,
    required this.daysUntil,
    required this.formatDate,
  });

  bool get _isOverdue => daysUntil == 'Vencido';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isOverdue ? const Color(0xFFFDF0E6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isOverdue
              ? AppTheme.terracotta.withAlpha(80)
              : const Color(0xFFE0D8CC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 18,
            color: _isOverdue ? AppTheme.terracotta : AppTheme.sage,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskType == 'water' ? 'Revisar tierra' : taskType,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isOverdue ? AppTheme.terracotta : AppTheme.dark,
                ),
              ),
              Text(
                formatDate(nextDueAt),
                style: GoogleFonts.figtree(fontSize: 12, color: AppTheme.muted),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isOverdue
                  ? AppTheme.terracotta.withAlpha(25)
                  : AppTheme.sageTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              daysUntil,
              style: GoogleFonts.figtree(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isOverdue ? AppTheme.terracotta : AppTheme.sage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String taskType;
  final String doneAt;
  const _HistoryRow({required this.taskType, required this.doneAt});

  @override
  Widget build(BuildContext context) {
    final label = switch (taskType) {
      'water'    => 'Regó la planta',
      'identify' => 'Planta identificada',
      _          => taskType,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.sage),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.dark)),
          const Spacer(),
          Text(doneAt,
              style: GoogleFonts.figtree(fontSize: 12, color: AppTheme.muted)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.sageTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.sage.withAlpha(60)),
      ),
      child: Text(label,
          style: GoogleFonts.figtree(
            fontSize: 12,
            color: AppTheme.sage,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
