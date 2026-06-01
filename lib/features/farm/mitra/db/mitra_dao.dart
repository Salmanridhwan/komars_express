import 'package:sqflite/sqflite.dart';
import '../models/mitra_model.dart';

class MitraDao {
  final Database _database;
  MitraDao(this._database);

  // ── Seed default mitra (KomarExpress) if not exists ───────────────────────
  Future<void> seedDefaultMitra() async {
    final existing = await _database.query(
      'mitra_partnerships',
      where: 'mitra_name = ?',
      whereArgs: ['KomarExpress'],
    );
    if (existing.isEmpty) {
      await _database.insert(
        'mitra_partnerships',
        MitraPartnership(
          mitraName: 'KomarExpress',
          companyName: 'PT Komars Express Nusantara',
          category: 'Restoran & Kuliner',
          contact: 'admin@komarsexpress.id',
          joinedDate: DateTime.now().toIso8601String().substring(0, 10),
          isActive: true,
          description:
              'Mitra restoran resmi Komars Farm. Mengelola pembelian hasil panen segar langsung dari petani mitra untuk kebutuhan operasional restoran Komars Express.',
          logoIcon: 'restaurant',
        ).toJson(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ── GET ALL ────────────────────────────────────────────────────────────────
  Future<List<MitraPartnership>> getAll() async {
    final maps = await _database.query(
      'mitra_partnerships',
      orderBy: 'joined_date DESC',
    );
    return maps.map((m) => MitraPartnership.fromJson(m)).toList();
  }

  // ── GET BY ID ──────────────────────────────────────────────────────────────
  Future<MitraPartnership?> getById(int id) async {
    final maps = await _database.query(
      'mitra_partnerships',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MitraPartnership.fromJson(maps.first);
  }

  // ── GET ACTIVE ─────────────────────────────────────────────────────────────
  Future<List<MitraPartnership>> getActive() async {
    final maps = await _database.query(
      'mitra_partnerships',
      where: 'is_active = 1',
      orderBy: 'mitra_name ASC',
    );
    return maps.map((m) => MitraPartnership.fromJson(m)).toList();
  }

  // ── COUNT ──────────────────────────────────────────────────────────────────
  Future<int> count() async {
    final result = await _database
        .rawQuery('SELECT COUNT(*) as count FROM mitra_partnerships');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── INSERT ─────────────────────────────────────────────────────────────────
  Future<int> insert(MitraPartnership mitra) async {
    return await _database.insert(
      'mitra_partnerships',
      mitra.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────
  Future<int> update(MitraPartnership mitra) async {
    return await _database.update(
      'mitra_partnerships',
      mitra.toJson(),
      where: 'id = ?',
      whereArgs: [mitra.id],
    );
  }
}
