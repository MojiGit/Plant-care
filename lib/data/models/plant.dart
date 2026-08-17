class Plant {
  final int? id;
  final String commonName;
  final String species;
  final String? photoPath;
  final String addedAt;
  final String lightNeed; // low | medium | high
  final int wateringIntervalDays;
  final bool isToxic;

  Plant({
    this.id,
    required this.commonName,
    required this.species,
    this.photoPath,
    required this.addedAt,
    required this.lightNeed,
    required this.wateringIntervalDays,
    required this.isToxic,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'common_name': commonName,
        'species': species,
        'photo_path': photoPath,
        'added_at': addedAt,
        'light_need': lightNeed,
        'watering_interval_days': wateringIntervalDays,
        'is_toxic': isToxic ? 1 : 0,
      };

  factory Plant.fromMap(Map<String, dynamic> map) => Plant(
        id: map['id'] as int?,
        commonName: map['common_name'] as String,
        species: map['species'] as String,
        photoPath: map['photo_path'] as String?,
        addedAt: map['added_at'] as String,
        lightNeed: map['light_need'] as String,
        wateringIntervalDays: map['watering_interval_days'] as int,
        isToxic: (map['is_toxic'] as int) == 1,
      );
}
