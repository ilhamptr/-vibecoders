import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_exception.dart';
import 'api_response.dart';
import 'request_auth.dart';

/// A file part for [ApiClient.postMultipart].
class ApiMultipartFile {
  const ApiMultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
  });

  /// Form field name the backend expects (e.g. `file`).
  final String field;
  final Uint8List bytes;
  final String filename;
}

/// HTTP client built on `package:http` so it runs on web (via fetch) as well
/// as native platforms.
class ApiClient {
  ApiClient({
    required String baseUrl,
    RequestAuth auth = const NoRequestAuth(),
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _auth = auth,
       _baseUri = _parseBaseUrl(baseUrl),
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final RequestAuth _auth;
  final http.Client _httpClient;
  final Duration timeout;

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send(
    method: 'GET',
    path: path,
    queryParameters: queryParameters,
    headers: headers,
    authenticated: authenticated,
  );

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send(
    method: 'POST',
    path: path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    authenticated: authenticated,
  );

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send(
    method: 'PUT',
    path: path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    authenticated: authenticated,
  );

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send(
    method: 'PATCH',
    path: path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    authenticated: authenticated,
  );

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send(
    method: 'DELETE',
    path: path,
    body: body,
    queryParameters: queryParameters,
    headers: headers,
    authenticated: authenticated,
  );

  /// Sends a `multipart/form-data` POST with text [fields] and [files].
  Future<ApiResponse> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<ApiMultipartFile> files = const [],
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    final request = http.MultipartRequest('POST', _resolve(path, null));
    // Content-Type (with boundary) is set by MultipartRequest itself.
    request.headers.addAll(
      await _headers(
        headers: headers,
        authenticated: authenticated,
        jsonBody: false,
      ),
    );
    request.fields.addAll(fields);
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
          contentType: _mediaTypeFor(file.filename),
        ),
      );
    }
    return _dispatch(request);
  }

  Future<ApiResponse> _send({
    required String method,
    required String path,
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required bool authenticated,
  }) async {
    final request = http.Request(method, _resolve(path, queryParameters));
    request.headers.addAll(
      await _headers(
        headers: headers,
        authenticated: authenticated,
        jsonBody: body != null,
      ),
    );
    if (body != null) {
      request.body = jsonEncode(body);
    }
    return _dispatch(request);
  }

  Future<Map<String, String>> _headers({
    Map<String, String>? headers,
    required bool authenticated,
    required bool jsonBody,
  }) async {
    final result = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      ...?headers,
    };
    if (authenticated) {
      await _auth.apply(result);
    }
    return result;
  }

  Future<ApiResponse> _dispatch(http.BaseRequest request) async {
    try {
      final streamed = await _httpClient.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);

      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        data: _decodeBody(response.body),
      );

      if (!apiResponse.isSuccess) {
        throw _mapFailure(apiResponse);
      }

      return apiResponse;
    } on TimeoutException {
      throw const ApiException(
        type: ApiFailureType.timeout,
        message: 'The request timed out.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(type: ApiFailureType.network, message: error.message);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        type: ApiFailureType.unknown,
        message: error.toString(),
      );
    }
  }

  Uri _resolve(String path, Map<String, String>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final base = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    final resolved = base.resolve(normalizedPath);

    if (queryParameters == null || queryParameters.isEmpty) {
      return resolved;
    }

    return resolved.replace(queryParameters: queryParameters);
  }

  static Uri _parseBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'Must be a valid absolute URL.',
      );
    }
    return uri;
  }

  static MediaType _mediaTypeFor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      'pdf' => MediaType('application', 'pdf'),
      _ => MediaType('application', 'octet-stream'),
    };
  }

  static Object? _decodeBody(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  static ApiException _mapFailure(ApiResponse response) {
    final message = _extractMessage(response.data);

    switch (response.statusCode) {
      case 400:
      case 422:
        return ApiException(
          type: ApiFailureType.validation,
          statusCode: response.statusCode,
          message: message,
          body: response.data,
        );
      case 401:
        return ApiException(
          type: ApiFailureType.unauthenticated,
          statusCode: response.statusCode,
          message: message,
          body: response.data,
        );
      case 403:
        return ApiException(
          type: ApiFailureType.forbidden,
          statusCode: response.statusCode,
          message: message,
          body: response.data,
        );
      case 404:
        return ApiException(
          type: ApiFailureType.notFound,
          statusCode: response.statusCode,
          message: message,
          body: response.data,
        );
      default:
        if (response.statusCode >= 500) {
          return ApiException(
            type: ApiFailureType.server,
            statusCode: response.statusCode,
            message: message,
            body: response.data,
          );
        }
        return ApiException(
          type: ApiFailureType.unknown,
          statusCode: response.statusCode,
          message: message,
          body: response.data,
        );
    }
  }

  static String _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;

      // FastAPI validation errors: {"detail": [{"loc": [...], "msg": "..."}]}
      if (detail is List) {
        final messages = detail
            .whereType<Map<String, dynamic>>()
            .map((item) {
              final loc = item['loc'];
              final field = loc is List && loc.isNotEmpty ? loc.last : null;
              final msg = item['msg'];
              if (msg is! String) return null;
              return field == null ? msg : '$field: $msg';
            })
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }

      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return 'Request failed.';
  }

  void close() => _httpClient.close();
}
