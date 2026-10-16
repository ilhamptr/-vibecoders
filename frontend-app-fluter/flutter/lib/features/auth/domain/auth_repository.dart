import '../../../domain/user/auth_session.dart';
import 'auth_credentials.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn(AuthCredentials credentials);

  Future<void> signOut();

  Future<AuthSession?> restoreSession();
}
