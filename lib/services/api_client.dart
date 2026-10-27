import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config.dart';

/// Error returned by the backend (or a network problem), with a message that
/// is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.status = 0, this.code, this.data});

  final String message;
  final int status;

  /// Machine-readable code from the backend, e.g. WRONG_PIN, PIN_NOT_SET.
  final String? code;

  /// `data` from the error body, if any (e.g. the failed transaction).
  final Object? data;

  bool get unauthorized => status == 401 && code == null;

  @override
  String toString() => message;
}

/// Small JSON client for the Paypoint API. Every response has the shape
/// `{ success, data, message }`; this returns `data` or throws [ApiException].
class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _http = client ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? token;

  /// Render's free plan sleeps; the first request can take ~50s to wake it.
  static const _timeout = Duration(seconds: 75);

  Future<dynamic> get(String path) => _send('GET', path);

  /// GET that returns the whole body (for extra fields next to `data`).
  Future<Map<String, dynamic>> getRaw(String path) async {
    final res = await _request('GET', path, null);
    final json = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && json['success'] != false) return json;
    throw _error(res, json);
  }
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) => _send('PUT', path, body);

  /// Like [post] but returns the whole decoded body, even for error statuses
  /// that still carry useful `data` (a failed payment includes the refunded
  /// transaction and the new balance).
  Future<Map<String, dynamic>> postRaw(String path, Map<String, dynamic> body) async {
    final res = await _request('POST', path, body);
    final json = _decode(res);
    if (res.statusCode >= 500 || res.statusCode == 401 && json['code'] == null) throw _error(res, json);
    return json;
  }

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final res = await _request(method, path, body);
    final json = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && json['success'] != false) return json['data'];
    throw _error(res, json);
  }

  Future<http.Response> _request(String method, String path, Map<String, dynamic>? body) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) req.body = jsonEncode(body);
      final streamed = await _http.send(req).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection. Check your network and try again.');
    } on http.ClientException {
      throw ApiException('Could not reach Paypoint. Check your connection and try again.');
    } on HandshakeException {
      throw ApiException('Secure connection failed. Please try again.');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final v = jsonDecode(utf8.decode(res.bodyBytes));
      return v is Map<String, dynamic> ? v : {'data': v};
    } catch (_) {
      return {
        'success': false,
        'message': res.statusCode == 502 || res.statusCode == 503
            ? 'Paypoint is starting up. Please try again in a moment.'
            : 'Unexpected response from server (${res.statusCode}).',
      };
    }
  }

  ApiException _error(http.Response res, Map<String, dynamic> json) => ApiException(
        (json['message'] as String?) ?? 'Something went wrong (${res.statusCode}).',
        status: res.statusCode,
        code: json['code'] as String?,
        data: json['data'],
      );
}
