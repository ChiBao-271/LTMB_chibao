import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class NoteDatabaseHelper {
  static final NoteDatabaseHelper instance = NoteDatabaseHelper._init();
  static Database? _database;

  NoteDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL, -- Thêm cột userId
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      priority INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      modifiedAt TEXT NOT NULL,
      tags TEXT,
      color TEXT,
      isCompleted INTEGER NOT NULL DEFAULT 0
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN userId TEXT NOT NULL DEFAULT "default_user"');
    }
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAllNotes(String userId) async {
    final db = await database;
    final result = await db.query('notes', where: 'userId = ?', whereArgs: [userId]);
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNoteById(int id, String userId) async {
    final db = await database;
    final result = await db.query('notes', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
    return result.isNotEmpty ? Note.fromMap(result.first) : null;
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [note.id, note.userId],
    );
  }

  Future<int> deleteNote(int id, String userId) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<Note>> getNotesByPriority(int priority, String userId) async {
    final db = await database;
    final result = await db.query('notes', where: 'priority = ? AND userId = ?', whereArgs: [priority, userId]);
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> searchNotes(String query, String userId) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: '(title LIKE ? OR content LIKE ?) AND userId = ?',
      whereArgs: ['%$query%', '%$query%', userId],
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    _database = null;
    await db.close();
  }
}