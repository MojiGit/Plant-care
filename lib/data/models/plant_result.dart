class PlantResult {
  final String commonName;
  final String species;
  final int wateringMax; // 1=Dry 2=Moist 3=Wet (Plant.id scale)
  final bool isToxic;

  const PlantResult({
    required this.commonName,
    required this.species,
    required this.wateringMax,
    required this.isToxic,
  });
}
