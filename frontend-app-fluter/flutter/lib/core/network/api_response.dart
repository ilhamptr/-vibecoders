class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    this.data,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Object? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}


