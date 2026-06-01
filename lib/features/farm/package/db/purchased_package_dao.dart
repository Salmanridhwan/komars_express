import 'package:sqflite/sqflite.dart';
import '../models/purchased_package_model.dart';

class PurchasedPackageDao {
  final Database _database;

  PurchasedPackageDao(this._database);

  Future<int> insertPurchasedPackage(PurchasedPackage purchased) async {
    try {
      return await _database.insert(
        'purchased_packages',
        purchased.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Error inserting purchased package: $e');
    }
  }

  Future<List<PurchasedPackage>> getPurchasedByUserId(int userId) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.rawQuery(
        '''
        SELECT 
          pp.id as purchase_id, pp.user_id, pp.package_id, pp.purchase_date, pp.payment_method, pp.price, pp.status,
          fp.id as id, fp.farm_type, fp.title, fp.description, fp.initial_capital_min, fp.initial_capital_rec,
          fp.harvest_time_days, fp.roi_months, fp.monthly_income_est, fp.steps, fp.equipment_list
        FROM purchased_packages pp
        JOIN farm_packages fp ON pp.package_id = fp.id
        WHERE pp.user_id = ?
        ORDER BY pp.purchase_date DESC
      ''',
        [userId],
      );

      return List.generate(maps.length, (i) {
        return PurchasedPackage.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Error retrieving purchased packages: $e');
    }
  }

  Future<bool> hasPurchased(int userId, int packageId) async {
    final maps = await _database.query(
      'purchased_packages',
      where: 'user_id = ? AND package_id = ?',
      whereArgs: [userId, packageId],
    );
    return maps.isNotEmpty;
  }
}
