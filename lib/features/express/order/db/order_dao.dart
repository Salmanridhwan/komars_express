import '../../../../core/database/database_helper.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderDao {
  final _db = DatabaseHelper.instance;

  Future<int> createOrder(OrderModel order, List<OrderItemModel> items) async {
    final db = await _db.database;
    int orderId = 0;

    await db.transaction((txn) async {
      // 1. Insert order header
      orderId = await txn.insert('orders', order.toMap());

      // 2. Insert order items
      for (var item in items) {
        final itemMap = item.copyWith(orderId: orderId).toMap();
        await txn.insert('order_items', itemMap);
      }
    });

    return orderId;
  }

  Future<List<OrderModel>> getHistory() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => OrderModel.fromMap(maps[i]));
  }

  Future<OrderModel?> getByCode(String code) async {
    final db = await _db.database;
    final maps = await db.query('orders', where: 'order_code = ?', whereArgs: [code], limit: 1);
    if (maps.isEmpty) return null;
    return OrderModel.fromMap(maps.first);
  }

  Future<List<OrderItemModel>> getOrderItems(int orderId) async {
    final db = await _db.database;
    // Perform raw query to join order items with menu details for name and category
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT oi.*, m.name AS menu_name, m.category AS menu_category 
      FROM order_items oi
      JOIN menu_items m ON oi.menu_item_id = m.id
      WHERE oi.order_id = ?
    ''', [orderId]);
    return List.generate(maps.length, (i) => OrderItemModel.fromMap(maps[i]));
  }

  Future<int> updateStatus(int id, String status) async {
    final db = await _db.database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> cancelOrder(int id) async {
    return await updateStatus(id, 'Dibatalkan');
  }
}
