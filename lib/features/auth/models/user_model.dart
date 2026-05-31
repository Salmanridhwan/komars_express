class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' | 'customer'
  final String? phoneNumber;
  final String? profileImage;
  final String? createdAt;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'customer',
    this.phoneNumber,
    this.profileImage,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone_number': phoneNumber,
        'profile_image': profileImage,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
        role: map['role'] as String? ?? 'customer',
        phoneNumber: map['phone_number'] as String?,
        profileImage: map['profile_image'] as String?,
        createdAt: map['created_at'] as String?,
      );

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? phoneNumber,
    String? profileImage,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        profileImage: profileImage ?? this.profileImage,
        createdAt: createdAt,
      );
}
