enum UserRole {
  admin,
  user,
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role']?.toString().toLowerCase() == 'admin'
          ? UserRole.admin
          : UserRole.user,
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'token': token,
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;
}