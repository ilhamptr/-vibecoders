import '../../domain/user/auth_session.dart';

/// Shared in-process session state without imposing a state-management package.
class AuthSessionManager {
  static final instance = AuthSessionManager();

  AuthSession? _session;

  AuthSession? get current => _session;
  bool get isAuthenticated => _session != null;

  void setSession(AuthSession session) {
    _session = session;
  }

  void clear() {
    _session = null;
  }
}
