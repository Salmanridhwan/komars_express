import '../models/user_model.dart';
import '../../../../core/database/database_helper.dart';

class UserDao {
  final _db = DatabaseHelper.instance;

  Future<int> register(UserModel user) async {
    final db = await _db.database;
    print('🔐 REGISTER: Inserting user with email: ${user.email}');
    final result = await db.insert('users', user.toMap());
    print('🔐 REGISTER: Insert result: $result');

    // Verify insertion
    final verify = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );
    print(
      '🔐 REGISTER: Verification - Found ${verify.length} users with email ${user.email}',
    );
    if (verify.isNotEmpty) {
      print('🔐 REGISTER: User data saved: $verify');
    }
    return result;
  }

  Future<UserModel?> login(String email, String password) async {
    final db = await _db.database;
    print('🔐 LOGIN: Attempting login with email: $email, password: $password');

    // Check all users in database
    final allUsers = await db.query('users');
    print('🔐 LOGIN: Total users in database: ${allUsers.length}');
    if (allUsers.isNotEmpty) {
      for (var user in allUsers) {
        print(
          '🔐 LOGIN: User record - email: ${user['email']}, password: ${user['password']}',
        );
      }
    }

    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    print('🔐 LOGIN: Query result: ${rows.length} rows found');
    if (rows.isNotEmpty) {
      print('🔐 LOGIN: User found: $rows');
    }
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<bool> emailExists(String email) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> updateProfile(UserModel user) async {
    final db = await _db.database;
    return await db.update(
      'users',
      {
        'name': user.name,
        'phone_number': user.phoneNumber,
        'profile_image': user.profileImage,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
