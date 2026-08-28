import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'somobay.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            address TEXT DEFAULT '',
            share_count INTEGER NOT NULL DEFAULT 1,
            joined_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE installments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            member_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            note TEXT DEFAULT '',
            paid_at TEXT NOT NULL,
            FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<List<Map<String, Object?>>> members() async {
    final db = await database;
    return db.query('members', orderBy: 'id DESC');
  }

  Future<int> addMember(Map<String, Object?> member) async {
    final db = await database;
    return db.insert('members', member);
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    await db.delete('installments', where: 'member_id = ?', whereArgs: [id]);
    return db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> installments() async {
    final db = await database;
    return db.rawQuery('''
      SELECT installments.*, members.name AS member_name
      FROM installments INNER JOIN members ON members.id = installments.member_id
      ORDER BY paid_at DESC, id DESC
    ''');
  }

  Future<int> addInstallment(Map<String, Object?> installment) async {
    final db = await database;
    return db.insert('installments', installment);
  }

  Future<double> totalCollected() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(amount), 0) AS total FROM installments');
    return (result.first['total'] as num).toDouble();
  }
}
