import '../../../../core/database/database_helper.dart';
import '../models/reservation_model.dart';

class ReservationDao {
  final _db = DatabaseHelper.instance;

  Future<int> insert(ReservationModel r) async {
    final db = await _db.database;
    return await db.insert('reservations', r.toMap());
  }

  /// Get all reservations for a user, joined with table info, newest first.
  Future<List<ReservationModel>> getByUser(int userId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT r.*, t.table_number, t.location
      FROM reservations r
      LEFT JOIN tables t ON r.table_id = t.id
      WHERE r.user_id = ?
      ORDER BY r.reservation_date DESC, r.start_time DESC
    ''', [userId]);
    return List.generate(maps.length, (i) => ReservationModel.fromMap(maps[i]));
  }

  /// Get ALL reservations (admin view), joined with table info.
  Future<List<ReservationModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT r.*, t.table_number, t.location
      FROM reservations r
      LEFT JOIN tables t ON r.table_id = t.id
      ORDER BY r.reservation_date DESC, r.start_time DESC
    ''');
    return List.generate(maps.length, (i) => ReservationModel.fromMap(maps[i]));
  }


  /// Get reservations booked for a specific table on a specific date (for conflict check).
  Future<List<ReservationModel>> getByTableAndDate(int tableId, String date) async {
    final db = await _db.database;
    final maps = await db.query(
      'reservations',
      where: "table_id = ? AND reservation_date = ? AND status != 'Dibatalkan'",
      whereArgs: [tableId, date],
    );
    return List.generate(maps.length, (i) => ReservationModel.fromMap(maps[i]));
  }

  /// Get all reservations on a specific date (used for real-time occupancy map).
  Future<List<ReservationModel>> getByDate(String date) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT r.*, t.table_number, t.location
      FROM reservations r
      LEFT JOIN tables t ON r.table_id = t.id
      WHERE r.reservation_date = ? AND r.status != 'Dibatalkan'
    ''', [date]);
    return List.generate(maps.length, (i) => ReservationModel.fromMap(maps[i]));
  }

  Future<ReservationModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT r.*, t.table_number, t.location
      FROM reservations r
      LEFT JOIN tables t ON r.table_id = t.id
      WHERE r.id = ?
      LIMIT 1
    ''', [id]);
    if (maps.isEmpty) return null;
    return ReservationModel.fromMap(maps.first);
  }

  Future<int> update(ReservationModel r) async {
    final db = await _db.database;
    return await db.update(
      'reservations',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  /// Soft-cancel: sets status = 'Dibatalkan'
  Future<int> cancel(int id) async {
    final db = await _db.database;
    return await db.update(
      'reservations',
      {'status': 'Dibatalkan'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
