import '../storage/token_storage.dart';

abstract interface class RequestAuth {
  /// Mutates [headers] to add any auth credentials for the request.
  Future<void> apply(Map<String, String> headers);
}

class NoRequestAuth implements RequestAuth {
  const NoRequestAuth();

  @override
  Future<void> apply(Map<String, String> headers) async {}
}

/// Enable only when the backend confirms Bearer-token authentication.
///
/// The token is treated as an opaque value; this class does not assume JWT.
class BearerRequestAuth implements RequestAuth {
  const BearerRequestAuth(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> apply(Map<String, String> headers) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return;

    headers['Authorization'] = 'Bearer $token';
  }
}
