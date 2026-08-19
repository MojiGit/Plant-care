import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/plant.dart';
import '../../data/plant_repository.dart';
import '../../domain/care_plan_engine.dart';
import '../../domain/gamification_engine.dart';
import '../../ui/app_theme.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _repo = PlantRepository();
  List<Map<String, dynamic>> _dueTasks = [];
  bool _loading = true;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _repo.getDueTasks();
    if (mounted) setState(() { _dueTasks = tasks; _loading = false; });
  }

  Future<void> _respond(Map<String, dynamic> task, CheckResult result) async {
    final scheduleId = task['id'] as int;
    final plantId    = task['plant_id'] as int;
    final dueAt      = DateTime.parse(task['next_due_at'] as String);
    final interval   = await _getInterval(plantId);

    setState(() => _processing.add(scheduleId));

    // Calcular próxima fecha
    final nextDue = CarePlanEngine.nextDueAt(
      result: result,
      interval: interval,
    );

    // Actualizar schedule
    await _repo.setSchedule(
      plantId: plantId,
      taskType: task['task_type'] as String,
      nextDueAt: nextDue,
    );

    // Registrar control en historial siempre
    final logType = switch (result) {
      CheckResult.watered     => 'water',
      CheckResult.allGood     => 'check_ok',
      CheckResult.remindLater => 'check_later',
    };
    await _repo.logCareTask(plantId: plantId, taskType: logType);

    // Puntos + streak solo si regó
    if (result == CheckResult.watered) {
      final stats  = await _repo.getUserStats();
      final points = stats['points'] as int;
      final streak = stats['streak_days'] as int;

      final pr = GamificationEngine.addPoints(
        currentPoints: points,
        action: PlantAction.water,
      );
      final sr = GamificationEngine.evaluateStreak(
        currentStreak: streak,
        dueDate: dueAt,
        completedAt: DateTime.now(),
      );

      await _repo.updateUserStats(
        points: pr.totalPoints,
        streakDays: sr.streakCount,
        lastActiveDate: DateTime.now().toIso8601String(),
      );

      if (mounted && pr.leveledUp) _showLevelUp(pr.level);
    }

    // Refrescar lista
    await _load();
  }

  Future<int> _getInterval(int plantId) async {
    final plant = await _repo.getPlant(plantId);
    return plant?.wateringIntervalDays ?? 7;
  }

  void _showLevelUp(Level level) {
    final labels = {
      Level.seedling:       'Seedling',
      Level.gardener:       'Gardener',
      Level.botanist:       'Botanist',
      Level.masterBotanist: 'Master Botanist',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.sage,
        content: Text(
          '¡Subiste de nivel! Ahora eres ${labels[level]}',
          style: GoogleFonts.figtree(color: AppTheme.cream, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _debugForceAllDue() async {
    final plants = await _repo.getPlants();
    for (final plant in plants) {
      await _repo.setSchedule(
        plantId: plant.id!,
        taskType: 'water',
        nextDueAt: DateTime.now().subtract(const Duration(days: 1)),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.sage))
            : _dueTasks.isEmpty
                ? _AllGoodState()
                : _TaskList(
                    tasks: _dueTasks,
                    processing: _processing,
                    onRespond: _respond,
                  ),
        // DEBUG — eliminar antes del release
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: AppTheme.terracotta,
            tooltip: 'Debug: forzar revisiones vencidas',
            onPressed: _debugForceAllDue,
            child: const Icon(Icons.bug_report_outlined, color: AppTheme.cream),
          ),
        ),
      ],
    );
  }
}

// ── Todo al día ───────────────────────────────────────────────────────────────

class _AllGoodState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppTheme.sage),
            const SizedBox(height: 24),
            Text('Todo al día',
                style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark)),
            const SizedBox(height: 12),
            Text('No hay plantas que revisar hoy. Vuelve mañana.',
                style: GoogleFonts.figtree(fontSize: 15, color: AppTheme.muted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Lista de tareas ───────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Set<int> processing;
  final Future<void> Function(Map<String, dynamic>, CheckResult) onRespond;

  const _TaskList({
    required this.tasks,
    required this.processing,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu plan de hoy',
                    style: GoogleFonts.caprasimo(fontSize: 22, color: AppTheme.dark)),
                const SizedBox(height: 4),
                Text('${tasks.length} planta${tasks.length > 1 ? 's' : ''} para revisar',
                    style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _TaskCard(
                task: tasks[i],
                isProcessing: processing.contains(tasks[i]['id'] as int),
                onRespond: (result) => onRespond(tasks[i], result),
              ),
              childCount: tasks.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isProcessing;
  final ValueChanged<CheckResult> onRespond;

  const _TaskCard({
    required this.task,
    required this.isProcessing,
    required this.onRespond,
  });

  bool get _isOverdue {
    final due = DateTime.parse(task['next_due_at'] as String);
    return due.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final plantName = task['common_name'] as String? ?? 'Planta';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _isOverdue
            ? Border.all(color: AppTheme.terracotta.withAlpha(80))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.dark.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isProcessing
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppTheme.sage, strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.sageTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppTheme.sage, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plantName,
                              style: GoogleFonts.caprasimo(fontSize: 15, color: AppTheme.dark)),
                          Text(
                            _isOverdue ? 'Revisión vencida' : 'Toca revisar hoy',
                            style: GoogleFonts.figtree(
                              fontSize: 12,
                              color: _isOverdue ? AppTheme.terracotta : AppTheme.muted,
                              fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Revisa la tierra de $plantName antes de regar.',
                  style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                // Botones de respuesta
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'Regué',
                        icon: Icons.water_drop_outlined,
                        color: AppTheme.sage,
                        onTap: () => onRespond(CheckResult.watered),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Todo bien',
                        icon: Icons.check_outlined,
                        color: AppTheme.muted,
                        onTap: () => onRespond(CheckResult.allGood),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Más tarde',
                        icon: Icons.schedule_outlined,
                        color: AppTheme.muted,
                        onTap: () => onRespond(CheckResult.remindLater),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.figtree(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
