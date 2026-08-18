import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_result.dart';
import '../../data/plant_repository.dart';
import '../../domain/care_plan_engine.dart';
import '../../services/plant_id_service.dart';
import '../../ui/app_theme.dart';

class AddPlantFlow extends StatefulWidget {
  const AddPlantFlow({super.key});

  @override
  State<AddPlantFlow> createState() => _AddPlantFlowState();
}

class _AddPlantFlowState extends State<AddPlantFlow> {
  int _step = 0;
  PlantResult? _result;
  LightCondition? _light;
  SoilType? _soil;
  bool _saving = false;

  void _onPlantIdentified(PlantResult result) {
    setState(() {
      _result = result;
      _step = 1;
    });
  }

  void _next() => setState(() => _step++);

  Future<void> _save() async {
    final result = _result;
    if (result == null || _light == null || _soil == null || _saving) return;
    setState(() => _saving = true);

    final interval = CarePlanEngine.checkInterval(
      waterNeed: CarePlanEngine.waterNeedFromInt(result.wateringMax),
      light: _light!,
      soil: _soil!,
    );
    final now = DateTime.now();
    final plant = Plant(
      commonName: result.commonName,
      species: result.species,
      addedAt: now.toIso8601String(),
      lightNeed: _light!.name,
      wateringIntervalDays: interval,
      isToxic: result.isToxic,
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
            _ScanStep(onIdentified: _onPlantIdentified),
            _ContextStep(
              light: _light,
              soil: _soil,
              onLightChanged: (v) => setState(() => _light = v),
              onSoilChanged: (v) => setState(() => _soil = v),
              onNext: _next,
            ),
            _ConfirmStep(
              result: _result,
              light: _light,
              soil: _soil,
              saving: _saving,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 0: Scan + Manual ─────────────────────────────────────────────────────

class _ScanStep extends StatefulWidget {
  final ValueChanged<PlantResult> onIdentified;
  const _ScanStep({required this.onIdentified});

  @override
  State<_ScanStep> createState() => _ScanStepState();
}

class _ScanStepState extends State<_ScanStep> {
  bool _isManual = false;
  final _controller = TextEditingController();
  PlantResult? _found;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() { _loading = true; _error = null; });
    try {
      final result = await PlantIdService.identify(image.path);
      if (mounted) widget.onIdentified(result);
    } catch (_) {
      setState(() => _error = 'No pudimos identificar la planta. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchPlant(String name) async {
    if (name.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; _found = null; });
    try {
      final result = await PlantIdService.search(name);
      setState(() => _found = result);
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.contains('not_found')
          ? 'No encontramos esa planta. Intenta con otro nombre.'
          : msg.contains('auth_error')
              ? 'API key inválida. Revisa secrets.dart.'
              : msg.contains('network_error')
                  ? 'Sin conexión. Verifica el internet del emulador.'
                  : 'Error: $msg');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identifica tu planta',
            style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark, height: 1.2),
          ),
          const SizedBox(height: 20),
          // Toggle cámara / manual
          Container(
            decoration: BoxDecoration(
              color: AppTheme.sageTint,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _ToggleBtn(
                  label: 'Foto',
                  icon: Icons.camera_alt_outlined,
                  active: !_isManual,
                  onTap: () => setState(() { _isManual = false; _found = null; _error = null; }),
                ),
                _ToggleBtn(
                  label: 'Nombre',
                  icon: Icons.edit_outlined,
                  active: _isManual,
                  onTap: () => setState(() => _isManual = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!_isManual) ...[
            // ── Modo cámara ──
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.sageTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 44, color: AppTheme.sage),
                  SizedBox(height: 10),
                  Text('Enfoca la planta y toma una foto'),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.terracotta)),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _loading ? null : _takePicture,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cream))
                  : const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(_loading ? 'Identificando…' : 'Tomar foto'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ] else ...[
            // ── Modo manual ──
            Text('Escribe el nombre de la planta',
                style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej: Pothos, Ficus, Cactus…',
                hintStyle: GoogleFonts.figtree(color: AppTheme.muted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0D8CC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0D8CC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.sage, width: 2),
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sage)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search, color: AppTheme.sage),
                        onPressed: () => _searchPlant(_controller.text),
                      ),
              ),
              onSubmitted: _searchPlant,
            ),
            if (_found != null) ...[
              const SizedBox(height: 20),
              _ResultCard(result: _found!),
            ] else if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.terracotta)),
            ],
            const Spacer(),
            FilledButton(
              onPressed: (!_loading && _found != null) ? () => widget.onIdentified(_found!) : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Continuar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [BoxShadow(color: AppTheme.dark.withAlpha(20), blurRadius: 4)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? AppTheme.sage : AppTheme.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppTheme.dark : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PlantResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sage, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.sageTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, color: AppTheme.sage, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.commonName,
                    style: GoogleFonts.caprasimo(fontSize: 15, color: AppTheme.dark)),
                Text(result.species,
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      color: AppTheme.muted,
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Context ───────────────────────────────────────────────────────────

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
              style: GoogleFonts.figtree(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.dark)),
          const SizedBox(height: 12),
          _ChoiceGroup<LightCondition>(
            selected: light,
            onChanged: onLightChanged,
            options: const [
              _Option(value: LightCondition.low,      icon: Icons.nights_stay_outlined, label: 'Poca luz',      sub: 'Interior sin ventana directa'),
              _Option(value: LightCondition.indirect,  icon: Icons.wb_cloudy_outlined,   label: 'Luz indirecta', sub: 'Cerca de ventana sin sol directo'),
              _Option(value: LightCondition.direct,    icon: Icons.wb_sunny_outlined,    label: 'Luz directa',   sub: 'Ventana con sol directo'),
            ],
          ),
          const SizedBox(height: 28),
          Text('¿Qué tipo de sustrato/maceta usas?',
              style: GoogleFonts.figtree(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.dark)),
          const SizedBox(height: 12),
          _ChoiceGroup<SoilType>(
            selected: soil,
            onChanged: onSoilChanged,
            options: const [
              _Option(value: SoilType.draining,  icon: Icons.grain_outlined,      label: 'Buen drenaje',    sub: 'Arena, cactus mix, perlita'),
              _Option(value: SoilType.normal,     icon: Icons.spa_outlined,        label: 'Normal',          sub: 'Sustrato universal'),
              _Option(value: SoilType.retaining,  icon: Icons.water_drop_outlined, label: 'Retiene humedad', sub: 'Turba o maceta sin agujeros'),
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
  final PlantResult? result;
  final LightCondition? light;
  final SoilType? soil;
  final bool saving;
  final VoidCallback onSave;

  const _ConfirmStep({
    required this.result,
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
    if (result == null || light == null || soil == null) return 0;
    return CarePlanEngine.checkInterval(
      waterNeed: CarePlanEngine.waterNeedFromInt(result!.wateringMax),
      light: light!,
      soil: soil!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Todo listo',
              style: GoogleFonts.caprasimo(fontSize: 26, color: AppTheme.dark)),
          const SizedBox(height: 6),
          Text('Revisa los datos antes de guardar.',
              style: GoogleFonts.figtree(fontSize: 14, color: AppTheme.muted)),
          const SizedBox(height: 28),
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
                Text(r.commonName,
                    style: GoogleFonts.caprasimo(fontSize: 20, color: AppTheme.dark)),
                Text(r.species,
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      color: AppTheme.muted,
                      fontStyle: FontStyle.italic,
                    )),
                const SizedBox(height: 16),
                if (r.isToxic) ...[
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
                            color: AppTheme.terracotta, size: 18),
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
