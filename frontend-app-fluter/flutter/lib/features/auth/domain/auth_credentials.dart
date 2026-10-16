/// Transport-neutral sign-in input.
///
/// Exact field names are intentionally supplied by the backend integration
/// after inspecting FastAPI's OpenAPI contract.
class AuthCredentials {
  const AuthCredentials(this.values);

  final Map<String, Object?> values;
}
