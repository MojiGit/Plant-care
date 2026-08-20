class PlantResult {
  final String species;
  final int wateringMax; // 1=Dry 2=Moist 3=Wet (Plant.id scale)
  final bool isToxic;
  final String? family;
  final String? description;
  final List<String> edibleParts;
  final List<String> propagationMethods;

  const PlantResult({
    required this.species,
    required this.wateringMax,
    required this.isToxic,
    this.family,
    this.description,
    this.edibleParts = const [],
    this.propagationMethods = const [],
  });
}
