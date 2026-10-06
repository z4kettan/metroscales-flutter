import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/auth/session_manager.dart';
import '../core/constants/api_constants.dart';
import 'token_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  factory ApiException.fromResponse(http.Response response) {
    var message = 'Something went wrong (${response.statusCode})';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final m = body['message'];
      if (m is String && m.isNotEmpty) message = m;
      if (m is List && m.isNotEmpty) message = m.join('\n');
    } catch (_) {}
    return ApiException(response.statusCode, message);
  }

  @override
  String toString() => message;
}

/// Talks to the Metro Scales API. Every response is `{success, data, message}`;
/// the methods here return `data`. An expired access token is refreshed once
/// and the request retried; if that fails the session ends.
class ApiClient {
  ApiClient({http.Client? httpClient, TokenService? tokens})
      : _http = httpClient ?? http.Client(),
        _tokens = tokens ?? TokenService();

  final http.Client _http;
  final TokenService _tokens;
  static Completer<bool>? _refreshing;

  Future<Map<String, String>> _headers(bool auth) async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await _tokens.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri uri(String path, [Map<String, dynamic>? query]) {
    final u = Uri.parse('${ApiConstants.baseUrl}$path');
    final q = <String, String>{
      for (final e in (query ?? {}).entries)
        if (e.value != null && e.value.toString().isNotEmpty) e.key: e.value.toString(),
    };
    return q.isEmpty ? u : u.replace(queryParameters: q);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() async => _http.get(uri(path, query), headers: await _headers(true)));

  Future<dynamic> post(String path, {Object? body, bool auth = true}) => _send(
        () async => _http.post(uri(path), headers: await _headers(auth), body: jsonEncode(body ?? {})),
        retryOn401: auth,
      );

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() async => _http.put(uri(path), headers: await _headers(true), body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() async => _http.patch(uri(path), headers: await _headers(true), body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(() async => _http.delete(uri(path, query), headers: await _headers(true)));

  /// Raw text, for CSV downloads.
  Future<String> getText(String path, {Map<String, dynamic>? query}) async {
    final res = await _raw(() async => _http.get(uri(path, query), headers: await _headers(true)));
    return utf8.decode(res.bodyBytes);
  }

  Future<dynamic> _send(Future<http.Response> Function() request, {bool retryOn401 = true}) async {
    final res = await _raw(request, retryOn401: retryOn401);
    if (res.body.isEmpty) return null;
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body is Map<String, dynamic> && body.containsKey('data') ? body['data'] : body;
  }

  Future<http.Response> _raw(Future<http.Response> Function() request, {bool retryOn401 = true}) async {
    http.Response res;
    try {
      res = await request().timeout(ApiConstants.timeout);
    } on TimeoutException {
      throw const ApiException(0, 'The server is taking too long. Check your internet and try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException(0, 'Cannot reach the server. Check your internet and try again.');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return res;

    if (res.statusCode == 401 && retryOn401) {
      if (await _refresh()) return _raw(request, retryOn401: false);
      await SessionManager.instance.onAuthFailure();
    }
    throw ApiException.fromResponse(res);
  }

  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = _refreshing = Completer<bool>();
    try {
      final token = await _tokens.getRefreshToken();
      if (token == null) {
        completer.complete(false);
      } else {
        final res = await _http
            .post(uri('/auth/refresh'),
                headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refreshToken': token}))
            .timeout(ApiConstants.timeout);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;
          await _tokens.saveTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      }
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }
}
