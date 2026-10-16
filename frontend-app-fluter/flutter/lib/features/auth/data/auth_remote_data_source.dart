import '../domain/auth_backend_result.dart';
import '../domain/auth_credentials.dart';

/// Implement this only after inspecting the actual FastAPI auth contract.
abstract interface class AuthRemoteDataSource {
  Future<AuthBackendResult> signIn(AuthCredentials credentials);

  Future<void> signOut();

  Future<AuthBackendResult?> restoreSession();
}
