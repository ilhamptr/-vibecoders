import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/login_repository.dart';
import 'session_role_data_source.dart';

/// Logs in against `POST /user/login`, persists the returned tokens, then reads
/// the role from `/user/me`. Caches a single (non-`both`) role for faster,
/// offline-friendly auto-login on the next launch.
class ApiLoginRepository implements LoginRepository {
  ApiLoginRepository(this._api, this._tokenStorage, this._meDataSource);

  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final SessionMeDataSource _meDataSource;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final ApiResponse response;
    try {
      response = await _api.post(
        '/user/login',
        authenticated: false,
        headers: _ngrokHeaders,
        body: {'email': email, 'password': password},
      );
    } on ApiException catch (error) {
      switch (error.type) {
        case ApiFailureType.notFound:
        case ApiFailureType.validation:
        case ApiFailureType.unauthenticated:
        case ApiFailureType.forbidden:
          throw InvalidCredentialsException(error.message);
        case ApiFailureType.network:
        case ApiFailureType.timeout:
        case ApiFailureType.server:
        case ApiFailureType.unknown:
          rethrow;
      }
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const RoleUnresolvedException('Respons login tidak dikenali.');
    }
    final accessToken = data['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const RoleUnresolvedException('Token tidak ditemukan pada respons.');
    }
    final refreshToken = data['refresh_token'];

    await _tokenStorage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken is String && refreshToken.isNotEmpty
          ? refreshToken
          : null,
    );

    // Role isn't in the login response; read it from /user/me.
    final me = await _meDataSource.fetchMe();
    switch (me.status) {
      case SessionMeStatus.resolved:
        final identity = me.identity!;
        if (identity.role != MeRole.both) {
          await _tokenStorage.writeUserRole(
            identity.role.asUserRole!.storageValue,
          );
        }
        return LoginOutcome(identity);
      case SessionMeStatus.invalid:
        await _tokenStorage.clear();
        throw const InvalidCredentialsException();
      case SessionMeStatus.indeterminate:
        throw const RoleUnresolvedException();
    }
  }
}
