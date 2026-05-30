import 'package:sqflite/sqflite.dart';
import '../models/farm_package_model.dart';

class FarmPackageDao {
  final Database _database;

  FarmPackageDao(this._database);

  // CREATE - Insert new farm package
  Future<int> insertPackage(FarmPackage package) async {
    try {
      final id = await _database.insert(
        'farm_packages',
        package.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Error inserting farm package: $e');
    }
  }

  // READ - Get all farm packages
  Future<List<FarmPackage>> getAllPackages() async {
    try {
      final maps = await _database.query('farm_packages');
      return List.generate(maps.length, (i) {
        return FarmPackage.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Error retrieving farm packages: $e');
    }
  }

  // READ - Get packages by farm type
  Future<List<FarmPackage>> getPackagesByFarmType(String farmType) async {
    try {
      final maps = await _database.query(
        'farm_packages',
        where: 'farm_type = ?',
        whereArgs: [farmType],
      );
      return List.generate(maps.length, (i) {
        return FarmPackage.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Error retrieving packages for farm type $farmType: $e');
    }
  }

  // READ - Get single package by ID
  Future<FarmPackage?> getPackageById(int id) async {
    try {
      final maps = await _database.query(
        'farm_packages',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return FarmPackage.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error retrieving farm package with id $id: $e');
    }
  }

  // UPDATE - Update existing package
  Future<int> updatePackage(FarmPackage package) async {
    try {
      final result = await _database.update(
        'farm_packages',
        package.toJson(),
        where: 'id = ?',
        whereArgs: [package.id],
      );
      return result;
    } catch (e) {
      throw Exception('Error updating farm package: $e');
    }
  }

  // DELETE - Delete package by ID
  Future<int> deletePackage(int id) async {
    try {
      final result = await _database.delete(
        'farm_packages',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result;
    } catch (e) {
      throw Exception('Error deleting farm package with id $id: $e');
    }
  }

  // READ - Count packages
  Future<int> getPackageCount() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM farm_packages',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Error counting farm packages: $e');
    }
  }
}
