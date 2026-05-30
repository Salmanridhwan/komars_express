import '../models/user_model.dart';
import '../../../../core/database/database_helper.dart';

class UserDao {
  final _db = DatabaseHelper.instance;

  Future<int> register(UserModel user) async {
    final db = await _db.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> login(String email, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<bool> emailExists(String email) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isNotEmpty;
  }

  Future<int> updateProfile(UserModel user) async {
    final db = await _db.database;
    return await db.update(
      'users',
      {'name': user.name, 'phone_number': user.phoneNumber, 'profile_image': user.profileImage},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
