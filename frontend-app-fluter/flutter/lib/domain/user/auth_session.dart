import 'user.dart';

class AuthSession {
  const AuthSession({required this.user, required this.authenticatedAt});

  final User user;
  final DateTime authenticatedAt;
}
