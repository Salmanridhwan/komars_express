import '../../../../core/database/database_helper.dart';
import '../models/table_model.dart';

class TableDao {
  final _db = DatabaseHelper.instance;

  Future<int> insert(TableModel table) async {
    final db = await _db.database;
    return await db.insert('tables', table.toMap());
  }

  Future<List<TableModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('tables', orderBy: 'table_number ASC');
    return List.generate(maps.length, (i) => TableModel.fromMap(maps[i]));
  }

  Future<List<TableModel>> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      'tables',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'location ASC, table_number ASC',
    );
    return List.generate(maps.length, (i) => TableModel.fromMap(maps[i]));
  }

  Future<TableModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('tables', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return TableModel.fromMap(maps.first);
  }

  Future<int> update(TableModel table) async {
    final db = await _db.database;
    return await db.update(
      'tables',
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  /// Soft-delete: sets is_active = 0
  Future<int> deactivate(int id) async {
    final db = await _db.database;
    return await db.update(
      'tables',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
