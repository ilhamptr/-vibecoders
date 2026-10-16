class AppEnvironment {
  const AppEnvironment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static void validate() {
    if (apiBaseUrl.trim().isEmpty) {
      throw StateError(
        'API_BASE_URL is not configured. '
        'Run Flutter with --dart-define=API_BASE_URL=<backend-url>.',
      );
    }

    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('API_BASE_URL is invalid: "$apiBaseUrl".');
    }
  }
}
