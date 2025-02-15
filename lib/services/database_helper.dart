import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'health_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE health_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          temperature REAL,
          bpm INTEGER,
          spo2 INTEGER,
          timestamp TEXT
        )''');
      },
    );
  }

  // Insert Data into SQLite
  Future<int> insertData(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('health_data', data);
  }

  // Retrieve all saved health data
  Future<List<Map<String, dynamic>>> getAllData() async {
    final db = await database;
    return await db.query('health_data');
  }

  // Delete all data (optional)
  Future<int> deleteAllData() async {
    final db = await database;
    return await db.delete('health_data');
  }

  // Copy the database to external storage (SD card)
  Future<void> copyDatabaseToExternalStorage() async {
    try {
      // Get the database file path
      String dbPath = join(await getDatabasesPath(), 'health_data.db');

      // Get the Downloads directory (safe for Android 10+)
      Directory? downloadsDir = Directory('/storage/emulated/0/Download');
      String newPath = "${downloadsDir.path}/health_data.db";

      // Copy the database file
      await File(dbPath).copy(newPath);
      print("✅ Database copied to: $newPath");

      // Refresh media scanner to make it visible in file manager
      refreshMediaScanner(newPath);
    } catch (e) {
      print("❌ Error copying database: $e");
    }
  }

// Force Android to detect the new file in File Manager
  void refreshMediaScanner(String filePath) {
    Process.run("am", [
      "broadcast",
      "-a",
      "android.intent.action.MEDIA_SCANNER_SCAN_FILE",
      "-d",
      "file://$filePath"
    ]);
  }

  // Get the last 7 days of health data
  Future<List<Map<String, dynamic>>> getLast7DaysData() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM health_data 
      ORDER BY timestamp DESC 
      LIMIT 7
    ''');
  }

}

// Create a singleton instance
final dbHelper = DatabaseHelper();
