import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vakt_fasting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const fastingLogTable = 'fasting_log';
    await db.execute('''
      CREATE TABLE $fastingLogTable (
        date TEXT PRIMARY KEY,
        status INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertOrUpdateLog(String date, int status) async {
    final db = await instance.database;
    await db.insert('fasting_log', {
      'date': date,
      'status': status,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> fetchAllLogs() async {
    final db = await instance.database;
    return await db.query('fasting_log');
  }

  Future<int> getStatusForDate(String date) async {
    final db = await instance.database;
    final results = await db.query(
      'fasting_log',
      columns: ['status'],
      where: 'date = ?',
      whereArgs: [date],
    );
    if (results.isNotEmpty) {
      return results.first['status'] as int;
    }
    return 0; // 0 = none
  }
}
