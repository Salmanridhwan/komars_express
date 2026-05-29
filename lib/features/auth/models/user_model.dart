class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? profileImage;
  final String? createdAt;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.profileImage,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'profile_image': profileImage,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
        phoneNumber: map['phone_number'] as String?,
        profileImage: map['profile_image'] as String?,
        createdAt: map['created_at'] as String?,
      );

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
    String? profileImage,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        profileImage: profileImage ?? this.profileImage,
        createdAt: createdAt,
      );
}
