enum ApiFailureType {
  network,
  timeout,
  unauthenticated,
  forbidden,
  validation,
  notFound,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.body,
  });

  final ApiFailureType type;
  final String message;
  final int? statusCode;
  final Object? body;

  @override
  String toString() =>
      'ApiException(type: $type, statusCode: $statusCode, message: $message)';
}
