import 'package:sqflite/sqflite.dart';
import '../models/financial_record_model.dart';

class FinancialRecordDao {
  final Database _database;

  FinancialRecordDao(this._database);

  // CREATE - Insert new financial record
  Future<int> insertRecord(FinancialRecord record) async {
    try {
      final id = await _database.insert(
        'financial_records',
        record.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Error inserting financial record: $e');
    }
  }

  // READ - Get all financial records
  Future<List<FinancialRecord>> getAllRecords() async {
    try {
      final maps = await _database.query(
        'financial_records',
        orderBy: 'record_date DESC',
      );
      return List.generate(maps.length, (i) {
        return FinancialRecord.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Error retrieving financial records: $e');
    }
  }

  // READ - Get records by user ID
  Future<List<FinancialRecord>> getRecordsByUserId(int userId) async {
    try {
      final maps = await _database.query(
        'financial_records',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'record_date DESC',
      );
      return List.generate(maps.length, (i) {
        return FinancialRecord.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Error retrieving records for user $userId: $e');
    }
  }

  // READ - Get records by user ID and farm type
  Future<List<FinancialRecord>> getRecordsByUserAndFarmType(
    int userId,
    String farmType,
  ) async {
    try {
      final maps = await _database.query(
        'financial_records',
        where: 'user_id = ? AND farm_type = ?',
        whereArgs: [userId, farmType],
        orderBy: 'record_date DESC',
      );
      return List.generate(maps.length, (i) {
        return FinancialRecord.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception(
        'Error retrieving records for user $userId and farm type $farmType: $e',
      );
    }
  }

  // READ - Get records by farm type
  Future<List<FinancialRecord>> getRecordsByFarmType(String farmType) async {
    try {
      final maps = await _database.query(
        'financial_records',
        where: 'farm_type = ?',
        whereArgs: [farmType],
        orderBy: 'record_date DESC',
      );
      return List.generate(maps.length, (i) {
        return FinancialRecord.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception('Error retrieving records for farm type $farmType: $e');
    }
  }

  // READ - Get single record by ID
  Future<FinancialRecord?> getRecordById(int id) async {
    try {
      final maps = await _database.query(
        'financial_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return FinancialRecord.fromJson(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error retrieving financial record with id $id: $e');
    }
  }

  // READ - Get records by date range
  Future<List<FinancialRecord>> getRecordsByDateRange(
    int userId,
    String startDate,
    String endDate,
  ) async {
    try {
      final maps = await _database.query(
        'financial_records',
        where: 'user_id = ? AND record_date >= ? AND record_date <= ?',
        whereArgs: [userId, startDate, endDate],
        orderBy: 'record_date DESC',
      );
      return List.generate(maps.length, (i) {
        return FinancialRecord.fromJson(maps[i]);
      });
    } catch (e) {
      throw Exception(
        'Error retrieving records between $startDate and $endDate: $e',
      );
    }
  }

  // UPDATE - Update existing record
  Future<int> updateRecord(FinancialRecord record) async {
    try {
      final result = await _database.update(
        'financial_records',
        record.toJson(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      return result;
    } catch (e) {
      throw Exception('Error updating financial record: $e');
    }
  }

  // DELETE - Delete record by ID
  Future<int> deleteRecord(int id) async {
    try {
      final result = await _database.delete(
        'financial_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result;
    } catch (e) {
      throw Exception('Error deleting financial record with id $id: $e');
    }
  }

  // READ - Get summary stats by user and farm type
  Future<Map<String, dynamic>?> getSummaryStats(
    int userId,
    String farmType,
  ) async {
    try {
      final result = await _database.rawQuery(
        '''
        SELECT 
          SUM(income) as total_income,
          SUM(expense) as total_expense,
          SUM(loss) as total_loss,
          SUM(net_profit) as total_profit,
          COUNT(*) as record_count
        FROM financial_records
        WHERE user_id = ? AND farm_type = ?
        ''',
        [userId, farmType],
      );
      if (result.isNotEmpty && result.first['total_income'] != null) {
        return result.first;
      }
      return null;
    } catch (e) {
      throw Exception('Error calculating summary stats: $e');
    }
  }

  // READ - Count records
  Future<int> getRecordCount() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM financial_records',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Error counting financial records: $e');
    }
  }
}
