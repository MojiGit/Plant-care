class AppConstants {
  static const String plantIdBaseUrl = 'https://plant.id/api/v3';
  static const String appName = 'Plant Care';

  // Gamification
  static const int pointsIdentify = 50;
  static const int pointsCareTask = 10;
  static const int pointsStreak = 5;

  // Levels
  static const Map<String, int> levels = {
    'Seedling': 0,
    'Gardener': 200,
    'Botanist': 600,
    'Master Botanist': 1500,
  };
}
