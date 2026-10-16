import '../../../core/storage/token_storage.dart';
import '../../../domain/user/user.dart';
import '../../../domain/user/user_role.dart';
import '../domain/session_bootstrap.dart';
import 'session_role_data_source.dart';

/// Decides, at app startup, whether a returning user can skip the login flow.
///
/// Flow:
/// 1. No access token stored -> [SessionAbsent].
/// 2. Token present -> `GET /user/me`.
///    - resolved + single role : cache the role, return [SessionRestored].
///    - resolved + `both`      : return [SessionRoleChoiceRequired].
///    - invalid (401/403)      : clear storage, return [SessionAbsent].
///    - indeterminate (offline / endpoint missing): fall back to a cached role
///      if one exists so the user still lands on a dashboard; otherwise
///      [SessionAbsent].
class SessionBootstrapper {
  const SessionBootstrapper({
    required TokenStorage tokenStorage,
    required SessionMeDataSource meDataSource,
  }) : _tokenStorage = tokenStorage,
       _meDataSource = meDataSource;

  final TokenStorage _tokenStorage;
  final SessionMeDataSource _meDataSource;

  Future<SessionBootstrapResult> bootstrap() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return const SessionAbsent();
    }

    final result = await _meDataSource.fetchMe();
    switch (result.status) {
      case SessionMeStatus.resolved:
        return _fromIdentity(result.identity!);

      case SessionMeStatus.invalid:
        await _tokenStorage.clear();
        return const SessionAbsent();

      case SessionMeStatus.indeterminate:
        // Offline or endpoint unavailable: keep the token and let a previously
        // cached role drive routing so the app still works offline.
        final cached = UserRole.tryParse(await _tokenStorage.readUserRole());
        if (cached != null) {
          return SessionRestored(
            role: cached,
            user: User(id: '', name: '', role: cached),
          );
        }
        return const SessionAbsent();
    }
  }

  Future<SessionBootstrapResult> _fromIdentity(MeIdentity identity) async {
    if (identity.role == MeRole.both) {
      // Don't cache a role here; the user picks one on the choice screen.
      return SessionRoleChoiceRequired(
        id: identity.id,
        fullName: identity.fullName,
      );
    }

    final role = identity.role.asUserRole!;
    await _tokenStorage.writeUserRole(role.storageValue);
    return SessionRestored(
      role: role,
      user: User(
        id: identity.id,
        name: identity.fullName,
        role: role,
        isVerified: identity.isVerified,
      ),
    );
  }
}
