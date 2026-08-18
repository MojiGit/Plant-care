import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/plant.dart';
import '../../data/plant_repository.dart';
import '../../domain/care_plan_engine.dart';
import '../../ui/app_theme.dart';

// Datos de prueba — reemplazados por Plant.id en PC402
const _mockCommonName  = 'Monstera';
const _mockSpecies     = 'Monstera deliciosa';
const _mockWateringMax = 2; // Moist
const _mockIsToxic     = true;

class AddPlantFlow extends StatefulWidget {
  const AddPlantFlow({super.key});

  @override
  State<AddPlantFlow> createState() => _AddPlantFlowState();
}

class _AddPlantFlowState extends State<AddPlantFlow> {
  int _step = 0;
  LightCondition? _light;
  SoilType? _soil;
  bool _saving = false;

  void _next() => setState(() => _step++);

  Future<void> _save() async {
    if (_light == null || _soil == null || _saving) return;
    setState(() => _saving = true);

    final interval = CarePlanEngine.checkInterval(
      waterNeed: CarePlanEngine.waterNeedFromInt(_mockWateringMax),
      light: _light!,
      soil: _soil!,
    );
    final now = DateTime.now();
    final plant = Plant(
      commonName: _mockCommonName,
      species: _mockSpecies,
      addedAt: now.toIso8601String(),
      lightNeed: _light!.name,
      wateringIntervalDays: interval,
      isToxic: _mockIsToxic,
    );
    final repo = PlantRepository();
    final plantId = await repo.addPlant(plant);
    await repo.setSchedule(
      plantId: plantId,
      taskType: 'water',
      nextDueAt: now.add(Duration(days: interval)),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Identificar', 'Contexto', 'Confirmar'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_step]),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _step,
          children: [
            _ScanStep(onNext: _next),
            _ContextStep(
              light: _light,
              soil: _soil,
              onLightChanged: (v) => setState(() => _light = v),
              onSoilChanged:  (v) => setState(() => _soil  = v),
              onNext: _next,
            ),
            _ConfirmStep(saving: _saving, light: _light, soil: _soil, onSave: _save),
          ],
        ),
      ),
    );
  }
}

// ── Step 0: Scan placeholder ──────────────────────────────────────────────────

class _ScanStep extends StatelessWidget {
  final VoidCallback onNext;
  const _ScanStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toma una foto\nde tu planta',
            style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Plant.id identificará la especie automáticamente.',
            style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted),
          ),
          const SizedBox(height: 28),
          // Placeholder de cámara
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: AppTheme.sageTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 48, color: AppTheme.sage),
                const SizedBox(height: 12),
                Text(
                  'Cámara disponible en PC402',
                  style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Resultado mock
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.dark.withAlpha(18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.sageTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppTheme.sage),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mockCommonName,
                      style: GoogleFonts.caprasimo(fontSize: 16, color: AppTheme.dark),
                    ),
                    Text(
                      _mockSpecies,
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        color: AppTheme.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sageTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Demo',
                    style: GoogleFonts.figtree(fontSize: 11, color: AppTheme.sage, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Light + Soil context ──────────────────────────────────────────────

class _ContextStep extends StatelessWidget {
  final LightCondition? light;
  final SoilType? soil;
  final ValueChanged<LightCondition> onLightChanged;
  final ValueChanged<SoilType> onSoilChanged;
  final VoidCallback onNext;

  const _ContextStep({
    required this.light,
    required this.soil,
    required this.onLightChanged,
    required this.onSoilChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuéntame sobre\nsu entorno',
            style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Usaré esta info para calcular cuándo revisar la tierra.',
            style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted),
          ),
          const SizedBox(height: 28),
          Text('¿Cómo es la luz donde estará?',
              style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.dark)),
          const SizedBox(height: 12),
          _ChoiceGroup<LightCondition>(
            selected: light,
            onChanged: onLightChanged,
            options: const [
              _Option(value: LightCondition.low,      icon: Icons.nights_stay_outlined, label: 'Poca luz',        sub: 'Interior sin ventana directa'),
              _Option(value: LightCondition.indirect,  icon: Icons.wb_cloudy_outlined,   label: 'Luz indirecta',   sub: 'Cerca de ventana sin sol directo'),
              _Option(value: LightCondition.direct,    icon: Icons.wb_sunny_outlined,    label: 'Luz directa',     sub: 'Ventana con sol directo'),
            ],
          ),
          const SizedBox(height: 28),
          Text('¿Qué tipo de sustrato/maceta usas?',
              style: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.dark)),
          const SizedBox(height: 12),
          _ChoiceGroup<SoilType>(
            selected: soil,
            onChanged: onSoilChanged,
            options: const [
              _Option(value: SoilType.draining,   icon: Icons.grain_outlined,         label: 'Buen drenaje',        sub: 'Arena, cactus mix, perlita'),
              _Option(value: SoilType.normal,      icon: Icons.spa_outlined,           label: 'Normal',              sub: 'Sustrato universal'),
              _Option(value: SoilType.retaining,   icon: Icons.water_drop_outlined,    label: 'Retiene humedad',     sub: 'Turba o maceta sin agujeros'),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: (light != null && soil != null) ? onNext : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class _Option<T> {
  final T value;
  final IconData icon;
  final String label;
  final String sub;
  const _Option({required this.value, required this.icon, required this.label, required this.sub});
}

class _ChoiceGroup<T> extends StatelessWidget {
  final T? selected;
  final ValueChanged<T> onChanged;
  final List<_Option<T>> options;

  const _ChoiceGroup({
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt.value;
        return GestureDetector(
          onTap: () => onChanged(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.sageTint : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.sage : const Color(0xFFE0D8CC),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(opt.icon, color: isSelected ? AppTheme.sage : AppTheme.muted, size: 22),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.label,
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.sage : AppTheme.dark,
                        )),
                    Text(opt.sub,
                        style: GoogleFonts.figtree(fontSize: 12, color: AppTheme.muted)),
                  ],
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(Icons.check_circle_rounded, color: AppTheme.sage, size: 20),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Step 2: Confirm ───────────────────────────────────────────────────────────

class _ConfirmStep extends StatelessWidget {
  final LightCondition? light;
  final SoilType? soil;
  final bool saving;
  final VoidCallback onSave;

  const _ConfirmStep({
    required this.light,
    required this.soil,
    required this.saving,
    required this.onSave,
  });

  String get _lightLabel => switch (light) {
        LightCondition.low      => 'Poca luz',
        LightCondition.indirect => 'Luz indirecta',
        LightCondition.direct   => 'Luz directa',
        null                    => '—',
      };

  String get _soilLabel => switch (soil) {
        SoilType.draining  => 'Buen drenaje',
        SoilType.normal    => 'Normal',
        SoilType.retaining => 'Retiene humedad',
        null               => '—',
      };

  int get _interval {
    if (light == null || soil == null) return 0;
    return CarePlanEngine.checkInterval(
      waterNeed: CarePlanEngine.waterNeedFromInt(_mockWateringMax),
      light: light!,
      soil: soil!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todo listo',
            style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark),
          ),
          const SizedBox(height: 6),
          Text(
            'Revisa los datos antes de guardar.',
            style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted),
          ),
          const SizedBox(height: 28),
          // Tarjeta resumen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.dark.withAlpha(18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mockCommonName,
                    style: GoogleFonts.caprasimo(fontSize: 20, color: AppTheme.dark)),
                Text(_mockSpecies,
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      color: AppTheme.muted,
                      fontStyle: FontStyle.italic,
                    )),
                const SizedBox(height: 16),
                // Alerta toxicidad
                if (_mockIsToxic) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.terracotta.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.terracotta, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tóxica para animales domésticos',
                            style: GoogleFonts.figtree(
                              fontSize: 13,
                              color: AppTheme.terracotta,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _InfoRow(icon: Icons.wb_sunny_outlined, label: 'Luz', value: _lightLabel),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.grain_outlined, label: 'Sustrato', value: _soilLabel),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Revisión de tierra',
                  value: 'Cada $_interval días',
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cream),
                  )
                : const Text('Guardar planta'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.muted),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.muted)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.figtree(
              fontSize: 13,
              color: AppTheme.dark,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
