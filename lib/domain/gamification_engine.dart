enum PlantAction { water, identify }

enum Level { seedling, gardener, botanist, masterBotanist }

class PointsResult {
  final int totalPoints;
  final int earned;
  final Level level;
  final Level previousLevel;

  const PointsResult({
    required this.totalPoints,
    required this.earned,
    required this.level,
    required this.previousLevel,
  });

  bool get leveledUp => level != previousLevel;
}

class StreakResult {
  final int streakCount;
  final bool broken;

  const StreakResult({required this.streakCount, required this.broken});
}

class GamificationEngine {
  static const _points = {
    PlantAction.water:    3,
    PlantAction.identify: 50,
  };

  static const _thresholds = {
    Level.seedling:       0,
    Level.gardener:       150,
    Level.botanist:       500,
    Level.masterBotanist: 1500,
  };

  static int pointsFor(PlantAction action) => _points[action]!;

  static Level levelFor(int points) {
    Level result = Level.seedling;
    for (final entry in _thresholds.entries) {
      if (points >= entry.value) result = entry.key;
    }
    return result;
  }

  /// Returns points needed to reach the next level, or null if already max.
  static int? pointsToNextLevel(int points) {
    final levels = Level.values;
    final current = levelFor(points);
    final nextIndex = levels.indexOf(current) + 1;
    if (nextIndex >= levels.length) return null;
    return _thresholds[levels[nextIndex]]! - points;
  }

  /// Call when user completes an action (water or identify).
  static PointsResult addPoints({
    required int currentPoints,
    required PlantAction action,
  }) {
    final earned = pointsFor(action);
    final newPoints = currentPoints + earned;
    return PointsResult(
      totalPoints: newPoints,
      earned: earned,
      level: levelFor(newPoints),
      previousLevel: levelFor(currentPoints),
    );
  }

  /// Call when a control is resolved.
  /// [dueDate] is the scheduled date; [completedAt] is when the user responded.
  /// Streak increments only if completed the same calendar day as due.
  /// If completedAt is null, the control was missed → streak breaks.
  static StreakResult evaluateStreak({
    required int currentStreak,
    required DateTime dueDate,
    DateTime? completedAt,
  }) {
    if (completedAt == null) {
      return const StreakResult(streakCount: 0, broken: true);
    }

    final sameDay = completedAt.year == dueDate.year &&
        completedAt.month == dueDate.month &&
        completedAt.day == dueDate.day;

    if (sameDay) {
      return StreakResult(streakCount: currentStreak + 1, broken: false);
    } else {
      // Completed late (after postponing past the due date) — no streak change
      return StreakResult(streakCount: currentStreak, broken: false);
    }
  }
}
