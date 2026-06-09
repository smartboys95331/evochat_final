import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'freedom.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute("CREATE TABLE users(id TEXT PRIMARY KEY, name TEXT, ip TEXT)");
      await db.execute("CREATE TABLE messages(id TEXT PRIMARY KEY, senderId TEXT, receiverId TEXT, text TEXT, timestamp TEXT)");
    });
  }

  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveMessage(Message msg) async {
    final db = await database;
    await db.insert('messages', msg.toMap());
  }

  Future<List<Message>> getMessages(String userId, String myId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('messages', 
      where: " (senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)",
      whereArgs: [myId, userId, userId, myId],
      orderBy: "timestamp ASC");
    
    return maps.map((m) => Message.fromMap(m, m['senderId'] == myId)).toList();
  }
}