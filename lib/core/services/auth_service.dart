import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' if (dart.library.io) 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = '${AppConfig.apiUrl}/auth';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  http.Client _buildClient() {
    if (kIsWeb) {
      final client = BrowserClient();
      client.withCredentials = true;
      return client;
    }
    return http.Client();
  }

  Future<bool> refresh() async {
    final res = await _buildClient().post(
      Uri.parse('$_baseUrl/refresh'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveSession(data['token'], null);
      return true;
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveSession(data['token'], data['defaultLanguage']);
      return data;
    }
    throw Exception('Login failed: ${res.body}');
  }

  Future<Map<String, dynamic>> register(String email, String password, String detectedLanguage) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'detectedLanguage': detectedLanguage}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      await _saveSession(data['token'], data['defaultLanguage']);
      return data;
    }
    throw Exception('Register failed: ${res.body}');
  }

  Future<void> forgotPassword(String email) async {
    await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    if (res.statusCode != 200) throw Exception('Reset failed');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.defaultLanguageKey);
  }

  Future<String?> getDefaultLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.defaultLanguageKey) ?? 'en';
  }

  Future<void> _saveSession(String token, String? lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
    if (lang != null) await prefs.setString(AppConfig.defaultLanguageKey, lang);
  }
}
