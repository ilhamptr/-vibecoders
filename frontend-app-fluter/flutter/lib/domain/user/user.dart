import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final bool isVerified;

  bool get isFarmer => role == UserRole.farmer;
  bool get isInvestor => role == UserRole.investor;

  User copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
