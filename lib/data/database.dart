import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'monstera.db'),
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        common_name TEXT NOT NULL,
        species TEXT NOT NULL,
        nickname TEXT,
        soil_type TEXT NOT NULL DEFAULT 'normal',
        water_need TEXT NOT NULL DEFAULT 'moist',
        photo_path TEXT,
        added_at TEXT NOT NULL,
        light_need TEXT NOT NULL,
        watering_interval_days INTEGER NOT NULL,
        is_toxic INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE care_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id INTEGER NOT NULL,
        task_type TEXT NOT NULL,
        done_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE care_schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id INTEGER NOT NULL,
        task_type TEXT NOT NULL,
        next_due_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants (id) ON DELETE CASCADE
      )
    ''');

    // Single-row table: INSERT once, UPDATE always after
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        points INTEGER NOT NULL DEFAULT 0,
        streak_days INTEGER NOT NULL DEFAULT 0,
        last_active_date TEXT
      )
    ''');

    await db.insert('user_stats', {'id': 1, 'points': 0, 'streak_days': 0});
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE plants ADD COLUMN nickname TEXT');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE plants ADD COLUMN soil_type TEXT NOT NULL DEFAULT 'normal'");
      await db.execute("ALTER TABLE plants ADD COLUMN water_need TEXT NOT NULL DEFAULT 'moist'");
    }
  }
}
