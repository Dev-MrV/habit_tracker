import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final int age;
  final String country;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.age,
    required this.country,
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    String? name,
    String? username,
    String? email,
    int? age,
    String? country,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      age: age ?? this.age,
      country: country ?? this.country,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }

  /// For Supabase (snake_case columns).
  Map<String, dynamic> toSupabase() => {
    'id': id,
    'name': name,
    'username': username,
    'age': age,
    'country': country,
    'avatar_url': avatarUrl,
  };

  factory UserModel.fromSupabase(Map<String, dynamic> map, {String? email}) =>
      UserModel(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        username: map['username'] as String? ?? '',
        email: email ?? '',
        age: map['age'] as int? ?? 0,
        country: map['country'] as String? ?? 'United States',
        avatarUrl: map['avatar_url'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
      );

  /// Local Hive cache (camelCase).
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'age': age,
    'country': country,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    username: map['username'] ?? '',
    email: map['email'] ?? '',
    age: map['age'] ?? 0,
    country: map['country'] ?? 'United States',
    avatarUrl: map['avatarUrl'] as String?,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'] as String)
        : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}