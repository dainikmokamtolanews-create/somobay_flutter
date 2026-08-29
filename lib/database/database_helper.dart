import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'somobay_somiti.db');
    _db = await openDatabase(path, version: 1, onCreate: _create);
    return _db!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT DEFAULT '',
        address TEXT DEFAULT '',
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        group_id INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_no TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        father TEXT DEFAULT '',
        mother TEXT DEFAULT '',
        spouse TEXT DEFAULT '',
        dob TEXT DEFAULT '',
        nid TEXT DEFAULT '',
        mobile TEXT DEFAULT '',
        address TEXT DEFAULT '',
        group_id INTEGER,
        group_code TEXT DEFAULT '',
        join_date TEXT DEFAULT '',
        comment TEXT DEFAULT '',
        assigned_field_worker_id INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        interest REAL DEFAULT 0,
        collection_type TEXT NOT NULL,
        start_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        installment_no INTEGER DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'draft'
      )
    ''');
    await db.execute('''
      CREATE TABLE bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        person_type TEXT NOT NULL,
        person_id INTEGER,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.insert('users', {
      'name': 'এডমিন',
      'username': 'admin',
      'password': '123456',
      'role': 'admin',
    });
    await db.insert('users', {
      'name': 'মাঠকর্মী',
      'username': 'field',
      'password': '1234',
      'role': 'field_worker',
    });
  }

  Future<Map<String, dynamic>?> login(String username, String password, String role) async {
    final db = await database;
    final rows = await db.query('users',
        where: 'username = ? AND password = ? AND role = ?',
        whereArgs: [username.trim(), password, role],
        limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? args, String? orderBy}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: args, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, Object?> values) async =>
      (await database).insert(table, values);

  Future<int> update(String table, Map<String, Object?> values, int id) async =>
      (await database).update(table, values, where: 'id = ?', whereArgs: [id]);

  Future<int> delete(String table, int id) async =>
      (await database).delete(table, where: 'id = ?', whereArgs: [id]);

  Future<void> updateAdminPassword(String oldPassword, String newPassword) async {
    final db = await database;
    final admin = await db.query('users',
        where: 'role = ? AND password = ?', whereArgs: ['admin', oldPassword], limit: 1);
    if (admin.isEmpty) throw Exception('পুরাতন পাসওয়ার্ড সঠিক নয়');
    await db.update('users', {'password': newPassword},
        where: 'role = ?', whereArgs: ['admin']);
  }

  Future<List<Map<String, dynamic>>> assignedMembers(int workerId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT m.*, g.name AS group_name
      FROM members m LEFT JOIN groups g ON g.id = m.group_id
      WHERE m.assigned_field_worker_id = ? OR (? = 0 AND m.assigned_field_worker_id IS NULL)
      ORDER BY m.name
    ''', [workerId, workerId]);
  }

  Future<Map<String, num>> totals() async {
    final db = await database;
    final members = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM members')) ?? 0;
    final loans = (await db.rawQuery('SELECT COALESCE(SUM(amount),0) AS total FROM loans')).first['total'] as num;
    final collection = (await db.rawQuery(
        "SELECT COALESCE(SUM(amount),0) AS total FROM collections WHERE status='posted'")).first['total'] as num;
    final balance = (await db.rawQuery(
        "SELECT COALESCE(SUM(CASE WHEN kind='জমা' THEN amount ELSE -amount END),0) AS total FROM bank_transactions")).first['total'] as num;
    return {'members': members, 'loans': loans, 'collection': collection, 'balance': balance};
  }
}
