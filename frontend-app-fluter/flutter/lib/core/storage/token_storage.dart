abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();

  Future<void> writeTokens({required String accessToken, String? refreshToken});

  /// Cached user role (`farmer` / `investor`) resolved at the last successful
  /// authentication. Used to route a returning user straight to the correct
  /// dashboard before (or without) a round-trip to the backend.
  Future<String?> readUserRole();
  Future<void> writeUserRole(String role);

  Future<void> clear();
}
