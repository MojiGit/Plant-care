import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/plant.dart';
import '../../data/plant_repository.dart';
import '../../domain/care_plan_engine.dart';
import '../../ui/app_theme.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;
  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _repo = PlantRepository();
  late final TextEditingController _nicknameCtrl;
  late LightCondition _light;
  late SoilType _soil;
  late int _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.plant.nickname ?? '');
    _light = LightCondition.values.firstWhere(
      (e) => e.name == widget.plant.lightNeed,
      orElse: () => LightCondition.indirect,
    );
    _soil = SoilType.values.firstWhere(
      (e) => e.name == widget.plant.soilType,
      orElse: () => SoilType.normal,
    );
    _days = widget.plant.wateringIntervalDays;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _recalcDays() {
    final waterNeed = WaterNeed.values.firstWhere(
      (e) => e.name == widget.plant.waterNeed,
      orElse: () => WaterNeed.moist,
    );
    final calculated = CarePlanEngine.checkInterval(
      waterNeed: waterNeed,
      light: _light,
      soil: _soil,
    );
    setState(() => _days = calculated);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final intervalChanged = _days != widget.plant.wateringIntervalDays;
    await _repo.updatePlant(
      id: widget.plant.id!,
      nicknameRaw: _nicknameCtrl.text,
      lightNeed: _light.name,
      soilType: _soil.name,
      wateringIntervalDays: _days,
    );
    if (intervalChanged) {
      await _repo.rescheduleAfterEdit(widget.plant.id!, _days);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.plant.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Nombre personalizado'),
            const SizedBox(height: 10),
            _NicknameField(controller: _nicknameCtrl),
            const SizedBox(height: 28),

            _SectionLabel('Luz disponible'),
            const SizedBox(height: 10),
            _OptionRow<LightCondition>(
              options: LightCondition.values,
              selected: _light,
              label: (v) => switch (v) {
                LightCondition.low      => 'Poca luz',
                LightCondition.indirect => 'Luz indirecta',
                LightCondition.direct   => 'Luz directa',
              },
              onChanged: (v) { setState(() => _light = v); _recalcDays(); },
            ),
            const SizedBox(height: 28),

            _SectionLabel('Tipo de tierra'),
            const SizedBox(height: 10),
            _OptionRow<SoilType>(
              options: SoilType.values,
              selected: _soil,
              label: (v) => switch (v) {
                SoilType.draining  => 'Drenante',
                SoilType.normal    => 'Normal',
                SoilType.retaining => 'Retentiva',
              },
              onChanged: (v) { setState(() => _soil = v); _recalcDays(); },
            ),
            const SizedBox(height: 28),

            _SectionLabel('Ciclo de revisión'),
            const SizedBox(height: 4),
            Text(
              'Días entre cada revisión de la tierra',
              style: GoogleFonts.figtree(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            _DaysStepper(
              days: _days,
              onChanged: (v) => setState(() => _days = v),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Guardar cambios',
                        style: GoogleFonts.figtree(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.caprasimo(fontSize: 15, color: AppTheme.dark),
      );
}

class _NicknameField extends StatelessWidget {
  final TextEditingController controller;
  const _NicknameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0D8CC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: GoogleFonts.figtree(fontSize: 15, color: AppTheme.dark),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Ej. Mi Monstera',
          hintStyle: GoogleFonts.figtree(color: AppTheme.muted),
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const _OptionRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt == options.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.sage : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.sage : const Color(0xFFE0D8CC),
                  ),
                ),
                child: Center(
                  child: Text(
                    label(opt),
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.cream : AppTheme.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DaysStepper extends StatelessWidget {
  final int days;
  final ValueChanged<int> onChanged;
  const _DaysStepper({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0D8CC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            color: days > 1 ? AppTheme.sage : AppTheme.muted,
            onPressed: days > 1 ? () => onChanged(days - 1) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$days días',
                style: GoogleFonts.caprasimo(fontSize: 22, color: AppTheme.dark),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: days < 60 ? AppTheme.sage : AppTheme.muted,
            onPressed: days < 60 ? () => onChanged(days + 1) : null,
          ),
        ],
      ),
    );
  }
}
