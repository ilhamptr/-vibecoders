import '../data/session_role_data_source.dart';

/// Signs a user in and resolves which dashboard to open.
///
/// `POST /user/login` returns tokens but no role, so after storing the token
/// the role is read from `GET /user/me` (via the same path used by auto-login).
abstract interface class LoginRepository {
  Future<LoginOutcome> login({required String email, required String password});
}

/// Result of a successful credential check. [identity] carries the role which
/// may be [MeRole.both], in which case the UI must ask the user to choose.
class LoginOutcome {
  const LoginOutcome(this.identity);

  final MeIdentity identity;
}

/// Raised when credentials are rejected (HTTP 404/422 from `/user/login`).
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException([this.message = 'Email atau password salah.']);
  final String message;

  @override
  String toString() => message;
}

/// Raised when the token was stored but the role could not be resolved
/// (e.g. `/user/me` unreachable). The session exists but needs a role.
class RoleUnresolvedException implements Exception {
  const RoleUnresolvedException([
    this.message = 'Gagal memuat profil. Coba lagi.',
  ]);
  final String message;

  @override
  String toString() => message;
}
