import '../../../../core/database/database_helper.dart';
import '../models/menu_item_model.dart';

class MenuDao {
  final _db = DatabaseHelper.instance;

  Future<int> insert(MenuItemModel item) async {
    final db = await _db.database;
    return await db.insert('menu_items', item.toMap());
  }

  Future<List<MenuItemModel>> getAll() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('menu_items');
    return List.generate(maps.length, (i) => MenuItemModel.fromMap(maps[i]));
  }

  Future<List<MenuItemModel>> getAvailable() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      where: 'is_available = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => MenuItemModel.fromMap(maps[i]));
  }

  Future<MenuItemModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('menu_items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return MenuItemModel.fromMap(maps.first);
  }

  Future<List<String>> getCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      distinct: true,
      columns: ['category'],
    );
    final Set<String> normalizedCategories = {};
    for (final m in maps) {
      if (m['category'] != null) {
        final cat = m['category'].toString().trim();
        if (cat.isNotEmpty) {
          final normalized = cat[0].toUpperCase() + cat.substring(1);
          normalizedCategories.add(normalized);
        }
      }
    }
    return normalizedCategories.toList();
  }

  Future<int> update(MenuItemModel item) async {
    final db = await _db.database;
    return await db.update(
      'menu_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
