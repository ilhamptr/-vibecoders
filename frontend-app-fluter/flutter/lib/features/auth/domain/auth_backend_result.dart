import '../../../domain/user/user.dart';

/// Normalized result produced by the backend-specific auth adapter.
///
/// Tokens are opaque strings; this does not assume JWT.
class AuthBackendResult {
  const AuthBackendResult({
    required this.user,
    this.accessToken,
    this.refreshToken,
  });

  final User user;
  final String? accessToken;
  final String? refreshToken;
}
