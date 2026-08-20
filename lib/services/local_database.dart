import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/material_order.dart';

class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'holding_orders.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number INTEGER NOT NULL UNIQUE,
          date TEXT NOT NULL,
          work TEXT NOT NULL,
          technician TEXT NOT NULL,
          service_order TEXT NOT NULL,
          job TEXT NOT NULL,
          items TEXT NOT NULL,
          signature TEXT
        )
      '''),
    );
    return _database!;
  }

  Future<int> nextNumber() async {
    final row = await (await _db).rawQuery('SELECT MAX(number) AS lastNumber FROM orders');
    return ((row.first['lastNumber'] as int?) ?? 388) + 1;
  }

  Future<void> save(MaterialOrder order) async {
    final map = order.toMap()..remove('id');
    await (await _db).insert('orders', map, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<MaterialOrder>> all() async {
    final rows = await (await _db).query('orders', orderBy: 'number DESC');
    return rows.map(MaterialOrder.fromMap).toList();
  }
}
