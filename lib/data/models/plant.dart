import 'dart:convert';

class Plant {
  final int? id;
  final String species;
  final String? nickname;
  final String soilType;
  final String waterNeed;
  final String? family;
  final String? description;
  final String? ediblePartsJson;
  final String? propagationMethodsJson;
  final String? photoPath;
  final String addedAt;
  final String lightNeed;
  final int wateringIntervalDays;
  final bool isToxic;

  Plant({
    this.id,
    required this.species,
    this.nickname,
    this.soilType = 'normal',
    this.waterNeed = 'moist',
    this.family,
    this.description,
    this.ediblePartsJson,
    this.propagationMethodsJson,
    this.photoPath,
    required this.addedAt,
    required this.lightNeed,
    required this.wateringIntervalDays,
    required this.isToxic,
  });

  String get displayName => nickname?.isNotEmpty == true ? nickname! : species;
  String? get displaySubtitle => nickname?.isNotEmpty == true ? species : null;

  List<String> get edibleParts =>
      ediblePartsJson != null ? List<String>.from(jsonDecode(ediblePartsJson!)) : [];

  List<String> get propagationMethods =>
      propagationMethodsJson != null ? List<String>.from(jsonDecode(propagationMethodsJson!)) : [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'species': species,
        'nickname': nickname,
        'soil_type': soilType,
        'water_need': waterNeed,
        'family': family,
        'description': description,
        'edible_parts': ediblePartsJson,
        'propagation_methods': propagationMethodsJson,
        'photo_path': photoPath,
        'added_at': addedAt,
        'light_need': lightNeed,
        'watering_interval_days': wateringIntervalDays,
        'is_toxic': isToxic ? 1 : 0,
      };

  factory Plant.fromMap(Map<String, dynamic> map) => Plant(
        id: map['id'] as int?,
        species: map['species'] as String,
        nickname: map['nickname'] as String?,
        soilType: (map['soil_type'] as String?) ?? 'normal',
        waterNeed: (map['water_need'] as String?) ?? 'moist',
        family: map['family'] as String?,
        description: map['description'] as String?,
        ediblePartsJson: map['edible_parts'] as String?,
        propagationMethodsJson: map['propagation_methods'] as String?,
        photoPath: map['photo_path'] as String?,
        addedAt: map['added_at'] as String,
        lightNeed: map['light_need'] as String,
        wateringIntervalDays: map['watering_interval_days'] as int,
        isToxic: (map['is_toxic'] as int) == 1,
      );
}
