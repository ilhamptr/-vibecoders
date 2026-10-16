import '../../../core/storage/token_storage.dart';
import '../../../domain/user/auth_session.dart';
import '../domain/auth_credentials.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._remoteDataSource,
    required this._tokenStorage,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> signIn(AuthCredentials credentials) async {
    final result = await _remoteDataSource.signIn(credentials);
    await _persistTokens(result.accessToken, result.refreshToken);

    return AuthSession(user: result.user, authenticatedAt: DateTime.now());
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final result = await _remoteDataSource.restoreSession();
    if (result == null) {
      await _tokenStorage.clear();
      return null;
    }

    await _persistTokens(result.accessToken, result.refreshToken);

    return AuthSession(user: result.user, authenticatedAt: DateTime.now());
  }

  Future<void> _persistTokens(String? accessToken, String? refreshToken) async {
    if (accessToken == null || accessToken.isEmpty) return;

    await _tokenStorage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
