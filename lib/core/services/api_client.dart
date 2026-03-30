import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' if (dart.library.io) 'package:http/http.dart';
import 'auth_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  http.Client _buildClient() {
    if (kIsWeb) {
      final client = BrowserClient();
      client.withCredentials = true;
      return client;
    }
    return http.Client();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String url) async {
    final client = _buildClient();
    final res = await client.get(Uri.parse(url), headers: await _headers());
    return _handleWithRefresh(res, () async => _buildClient().get(Uri.parse(url), headers: await _headers()));
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final client = _buildClient();
    final res = await client.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
    return _handleWithRefresh(res, () async => _buildClient().post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body)));
  }

  Future<dynamic> patch(String url, Map<String, dynamic> body) async {
    final client = _buildClient();
    final res = await client.patch(Uri.parse(url), headers: await _headers(), body: jsonEncode(body));
    return _handleWithRefresh(res, () async => _buildClient().patch(Uri.parse(url), headers: await _headers(), body: jsonEncode(body)));
  }

  Future<void> delete(String url) async {
    final client = _buildClient();
    final res = await client.delete(Uri.parse(url), headers: await _headers());
    if (res.statusCode == 401) {
      final refreshed = await AuthService().refresh();
      if (refreshed) {
        final retried = await _buildClient().delete(Uri.parse(url), headers: await _headers());
        if (retried.statusCode >= 400) throw Exception('DELETE $url failed: ${retried.body}');
        return;
      }
      await AuthService().logout();
      throw Exception('401: Unauthorized');
    }
    if (res.statusCode >= 400) throw Exception('DELETE $url failed: ${res.body}');
  }

  Future<dynamic> _handleWithRefresh(http.Response res, Future<http.Response> Function() retry) async {
    if (res.statusCode == 401) {
      final refreshed = await AuthService().refresh();
      if (refreshed) {
        final retried = await retry();
        return _handle(retried);
      }
      await AuthService().logout();
      throw Exception('401: Unauthorized');
    }
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw Exception('${res.statusCode}: ${res.body}');
  }
}
