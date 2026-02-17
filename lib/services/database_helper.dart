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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE data_collection_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cropTypeId TEXT,
        type TEXT,
        subtype TEXT,
        imagePath TEXT,
        createdAt TEXT
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

  Future<int> insertRequest(Map<String, dynamic> request) async {
    final db = await instance.database;
    return await db.insert('data_collection_queue', request);
  }

  Future<List<Map<String, dynamic>>> getReferencedRequests() async {
    final db = await instance.database;
    return await db.query('data_collection_queue', orderBy: 'createdAt ASC');
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
