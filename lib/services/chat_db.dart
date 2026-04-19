import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';

class ChatDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), "chat.db");

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT,
            text TEXT,
            source TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );

    return _db!;
  }

  /// ➕ thêm tin nhắn
  static Future<void> insert(ChatMessage msg) async {
    final db = await database;
    await db.insert("chat", msg.toMap());
  }

  /// 📥 lấy toàn bộ chat
  static Future<List<ChatMessage>> getAll() async {
    final db = await database;
    final res = await db.query("chat", orderBy: "timestamp ASC");

    return res.map((e) => ChatMessage.fromMap(e)).toList();
  }

  /// 🗑 xoá chat
  static Future<void> clear() async {
    final db = await database;
    await db.delete("chat");
  }
}