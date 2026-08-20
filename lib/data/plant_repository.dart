import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'models/plant.dart';

class PlantRepository {
  Future<Database> get _db async => AppDatabase.instance;

  // ── Plants ──────────────────────────────────────────────────────────────

  Future<int> addPlant(Plant plant) async {
    final db = await _db;
    return db.insert('plants', plant.toMap());
  }

  Future<List<Plant>> getPlants() async {
    final db = await _db;
    final rows = await db.query('plants', orderBy: 'added_at DESC');
    return rows.map(Plant.fromMap).toList();
  }

  Future<Plant?> getPlant(int id) async {
    final db = await _db;
    final rows = await db.query('plants', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Plant.fromMap(rows.first);
  }

  Future<void> deletePlant(int id) async {
    final db = await _db;
    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePlant({
    required int id,
    required String nicknameRaw,
    required String lightNeed,
    required String soilType,
    required int wateringIntervalDays,
  }) async {
    final db = await _db;
    await db.update(
      'plants',
      {
        'nickname': nicknameRaw.trim().isEmpty ? null : nicknameRaw.trim(),
        'light_need': lightNeed,
        'soil_type': soilType,
        'watering_interval_days': wateringIntervalDays,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateNickname(int id, String? nickname) async {
    final db = await _db;
    await db.update(
      'plants',
      {'nickname': nickname?.trim().isEmpty == true ? null : nickname?.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Care log ─────────────────────────────────────────────────────────────

  Future<void> logCareTask({
    required int plantId,
    required String taskType,
  }) async {
    final db = await _db;
    await db.insert('care_log', {
      'plant_id': plantId,
      'task_type': taskType,
      'done_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCareHistory(int plantId) async {
    final db = await _db;
    return db.query(
      'care_log',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'done_at DESC',
    );
  }

  // ── Care schedule ─────────────────────────────────────────────────────────

  Future<void> setSchedule({
    required int plantId,
    required String taskType,
    required DateTime nextDueAt,
  }) async {
    final db = await _db;
    // Replace existing schedule entry for this plant+task combination
    await db.delete(
      'care_schedule',
      where: 'plant_id = ? AND task_type = ?',
      whereArgs: [plantId, taskType],
    );
    await db.insert('care_schedule', {
      'plant_id': plantId,
      'task_type': taskType,
      'next_due_at': nextDueAt.toIso8601String(),
    });
  }

  Future<Map<int, DateTime>> getNextDueDates() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT plant_id, MIN(next_due_at) AS next_due_at FROM care_schedule GROUP BY plant_id',
    );
    return {
      for (final row in rows)
        row['plant_id'] as int:
            DateTime.parse(row['next_due_at'] as String).toLocal(),
    };
  }

  Future<List<Map<String, dynamic>>> getPlantSchedule(int plantId) async {
    final db = await _db;
    return db.query(
      'care_schedule',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'next_due_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getDueTasks() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return db.rawQuery('''
      SELECT cs.*, p.common_name
      FROM care_schedule cs
      JOIN plants p ON p.id = cs.plant_id
      WHERE cs.next_due_at <= ?
      ORDER BY cs.next_due_at ASC
    ''', [now]);
  }

  // ── User stats ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserStats() async {
    final db = await _db;
    final rows = await db.query('user_stats', where: 'id = 1');
    return rows.first;
  }

  Future<void> updateUserStats({
    required int points,
    required int streakDays,
    required String lastActiveDate,
  }) async {
    final db = await _db;
    await db.update(
      'user_stats',
      {
        'points': points,
        'streak_days': streakDays,
        'last_active_date': lastActiveDate,
      },
      where: 'id = 1',
    );
  }
}
