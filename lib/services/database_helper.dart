import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('data_collection.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE data_collection_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cropTypeId TEXT,
        type TEXT,
        subtype TEXT,
        imagePath TEXT,
        createdAt TEXT,
        uploaded INTEGER NOT NULL DEFAULT 0,
        uploadedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE api_cache (
        endpoint TEXT PRIMARY KEY,
        response_body TEXT,
        updatedAt INTEGER
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE data_collection_queue ADD COLUMN uploaded INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE data_collection_queue ADD COLUMN uploadedAt TEXT',
      );
    }
  }

  Future<int> insertRequest(Map<String, dynamic> request) async {
    final db = await instance.database;
    return await db.insert('data_collection_queue', request);
  }

  Future<List<Map<String, dynamic>>> getReferencedRequests() async {
    final db = await instance.database;
    return await db.query(
      'data_collection_queue',
      orderBy: 'uploaded ASC, createdAt ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final db = await instance.database;
    return await db.query(
      'data_collection_queue',
      where: 'uploaded = 0',
      orderBy: 'createdAt ASC',
    );
  }

  Future<int> markUploaded(int id) async {
    final db = await instance.database;
    return await db.update(
      'data_collection_queue',
      {'uploaded': 1, 'uploadedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateRequestImagePath(int id, String imagePath) async {
    final db = await instance.database;
    return await db.update(
      'data_collection_queue',
      {'imagePath': imagePath, 'uploaded': 0, 'uploadedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRequest(int id) async {
    final db = await instance.database;
    return await db.delete(
      'data_collection_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cacheResponse(String endpoint, String body) async {
    final db = await instance.database;
    await db.insert('api_cache', {
      'endpoint': endpoint,
      'response_body': body,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // debugPrint('Cached response for $endpoint');
  }

  Future<String?> getCachedResponse(String endpoint) async {
    final db = await instance.database;
    final result = await db.query(
      'api_cache',
      columns: ['response_body'],
      where: 'endpoint = ?',
      whereArgs: [endpoint],
    );

    if (result.isNotEmpty) {
      return result.first['response_body'] as String;
    }
    return null;
  }
}
