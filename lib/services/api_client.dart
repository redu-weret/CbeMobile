import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/api_response.dart';
import 'session.dart';

/// Thin HTTP wrapper around package:http with:
///  - automatic `Authorization: Bearer <token>` header
///  - silent token refresh on 401 (single-flight), then retry once
///  - ApiResponse-aware error mapping
///  - multipart upload support (profile picture)
class ApiClient {
  static const Duration timeout = Duration(seconds: 15);

  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (json) headers['Content-Type'] = 'application/json';
    final token = Session.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required bool json,
    bool retried = false,
  }) async {
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
          'The server took too long to respond. Check the server address and your connection.');
    } on http.ClientException catch (e) {
      throw ApiException(
          'Could not reach the server. Make sure the backend is running and '
          'this device can reach it. (${e.message})');
    } on ApiException {
      rethrow;
    }

    if (response.statusCode == 401 && !retried) {
      final refreshed = await Session.instance.refresh();
      if (refreshed) {
        return _send(request, json: json, retried: true);
      }
      // Refresh failed — force sign-out so the UI returns to the login screen.
      await Session.instance.clear();
      throw const ApiException('Your session has expired. Please sign in again.',
          statusCode: 401);
    }

    if (response.statusCode >= 400) {
      throw _mapError(response);
    }
    return response;
  }

  ApiException _mapError(http.Response response) {
    String message = 'Request failed (HTTP ${response.statusCode}).';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['message'] is String) {
        message = body['message'] as String;
      }
    } catch (_) {
      // Non-JSON error body — keep the generic message.
    }
    return ApiException(message, statusCode: response.statusCode);
  }

  // ---- Generic helpers ----------------------------------------------------

  Future<ApiResponse<T>> getJson<T>(
    String path,
    T Function(dynamic) parser, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse(AppConfig.url(path)).replace(queryParameters: query);
    final response = await _send(
      () async => _client.get(uri, headers: await _headers()),
      json: false,
    );
    return _parseApi<T>(response, parser);
  }

  /// GET a JSON array response through the same refresh/error pipeline.
  /// The backend wraps arrays in ApiResponse, so the envelope is unwrapped here.
  Future<List<T>> getList<T>(
    String path,
    T Function(Map<String, dynamic>) parser, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse(AppConfig.url(path)).replace(queryParameters: query);
    final response = await _send(
      () async => _client.get(uri, headers: await _headers(json: false)),
      json: false,
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Unexpected server response.');
    }
    if (body['success'] == false) {
      throw ApiException(body['message']?.toString() ?? 'Request failed.');
    }
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList();
  }

  Future<ApiResponse<T>> postJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) parser,
  ) async {
    final response = await _send(
      () async => _client.post(
        Uri.parse(AppConfig.url(path)),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
      json: true,
    );
    return _parseApi<T>(response, parser);
  }

  Future<ApiResponse<T>> putJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic) parser,
  ) async {
    final response = await _send(
      () async => _client.put(
        Uri.parse(AppConfig.url(path)),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
      json: true,
    );
    return _parseApi<T>(response, parser);
  }

  Future<ApiResponse<T>> deleteJson<T>(
    String path,
    T Function(dynamic) parser,
  ) async {
    final response = await _send(
      () async => _client.delete(
        Uri.parse(AppConfig.url(path)),
        headers: await _headers(json: false),
      ),
      json: false,
    );
    return _parseApi<T>(response, parser);
  }

  /// Multipart upload (used for profile pictures). The request is intentionally
  /// NOT encrypted and not JSON — the backend middleware skips these.
  Future<ApiResponse<T>> postMultipart<T>(
    String path,
    http.MultipartFile file,
    T Function(dynamic) parser,
  ) async {
    final request =
        http.MultipartRequest('POST', Uri.parse(AppConfig.url(path)));
    request.headers.addAll(await _headers(json: false));
    request.files.add(file);
    final streamed = await _send(
      () async => http.Response.fromStream(
          await _client.send(request).timeout(timeout)),
      json: false,
    );
    return _parseApi<T>(streamed, parser);
  }

  Future<ApiResponse<T>> putMultipart<T>(
    String path,
    http.MultipartFile file,
    T Function(dynamic) parser,
  ) async {
    final request =
        http.MultipartRequest('PUT', Uri.parse(AppConfig.url(path)));
    request.headers.addAll(await _headers(json: false));
    request.files.add(file);
    final streamed = await _send(
      () async => http.Response.fromStream(
          await _client.send(request).timeout(timeout)),
      json: false,
    );
    return _parseApi<T>(streamed, parser);
  }

  /// Download a binary file (report export). Throws ApiException on failure.
  Future<List<int>> download(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse(AppConfig.url(path)).replace(queryParameters: query);
    final response = await _send(
      () async => _client.get(uri, headers: await _headers(json: false)),
      json: false,
    );
    return response.bodyBytes;
  }

  // ---- Parsing -------------------------------------------------------------

  ApiResponse<T> _parseApi<T>(
    http.Response response,
    T Function(dynamic) parser,
  ) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Unexpected server response.');
    }
    return ApiResponse<T>.fromJson(body, parser);
  }
}
