class Plant {
  final int? id;
  final String commonName;
  final String species;
  final String? nickname;
  final String? photoPath;
  final String addedAt;
  final String lightNeed;
  final int wateringIntervalDays;
  final bool isToxic;

  Plant({
    this.id,
    required this.commonName,
    required this.species,
    this.nickname,
    this.photoPath,
    required this.addedAt,
    required this.lightNeed,
    required this.wateringIntervalDays,
    required this.isToxic,
  });

  String get displayName => nickname?.isNotEmpty == true ? nickname! : species;
  String? get displaySubtitle => nickname?.isNotEmpty == true ? species : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'common_name': commonName,
        'species': species,
        'nickname': nickname,
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
        nickname: map['nickname'] as String?,
        photoPath: map['photo_path'] as String?,
        addedAt: map['added_at'] as String,
        lightNeed: map['light_need'] as String,
        wateringIntervalDays: map['watering_interval_days'] as int,
        isToxic: (map['is_toxic'] as int) == 1,
      );
}
