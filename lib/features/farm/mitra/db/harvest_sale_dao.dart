import 'package:sqflite/sqflite.dart';
import '../models/harvest_sale_model.dart';

class HarvestSaleDao {
  final Database _database;
  HarvestSaleDao(this._database);

  // ── INSERT ─────────────────────────────────────────────────────────────────
  Future<int> insert(HarvestSale sale) async {
    return await _database.insert(
      'harvest_sales',
      sale.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── GET ALL (for Express Admin inbox) ─────────────────────────────────────
  Future<List<HarvestSale>> getAll() async {
    final maps = await _database.rawQuery('''
      SELECT hs.*, u.name as farmer_name
      FROM harvest_sales hs
      LEFT JOIN users u ON hs.farmer_user_id = u.id
      ORDER BY hs.created_at DESC
    ''');
    return maps.map((m) => HarvestSale.fromJson(m)).toList();
  }

  // ── GET BY FARMER ─────────────────────────────────────────────────────────
  Future<List<HarvestSale>> getByFarmer(int userId) async {
    final maps = await _database.query(
      'harvest_sales',
      where: 'farmer_user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => HarvestSale.fromJson(m)).toList();
  }

  // ── GET BY MITRA ──────────────────────────────────────────────────────────
  Future<List<HarvestSale>> getByMitra(int mitraId) async {
    final maps = await _database.rawQuery('''
      SELECT hs.*, u.name as farmer_name
      FROM harvest_sales hs
      LEFT JOIN users u ON hs.farmer_user_id = u.id
      WHERE hs.mitra_id = ?
      ORDER BY hs.created_at DESC
    ''', [mitraId]);
    return maps.map((m) => HarvestSale.fromJson(m)).toList();
  }

  // ── GET BY STATUS ─────────────────────────────────────────────────────────
  Future<List<HarvestSale>> getByStatus(String status) async {
    final maps = await _database.rawQuery('''
      SELECT hs.*, u.name as farmer_name
      FROM harvest_sales hs
      LEFT JOIN users u ON hs.farmer_user_id = u.id
      WHERE hs.status = ?
      ORDER BY hs.created_at DESC
    ''', [status]);
    return maps.map((m) => HarvestSale.fromJson(m)).toList();
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<int> updateStatus(int id, String status) async {
    return await _database.update(
      'harvest_sales',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── COUNT PENDING ─────────────────────────────────────────────────────────
  Future<int> countPending() async {
    final result = await _database.rawQuery(
      "SELECT COUNT(*) as count FROM harvest_sales WHERE status = 'Menunggu'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── COUNT ALL ─────────────────────────────────────────────────────────────
  Future<int> countAll() async {
    final result = await _database
        .rawQuery('SELECT COUNT(*) as count FROM harvest_sales');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
