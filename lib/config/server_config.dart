// telemedicina-app/lib/config/server_config.dart
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _key = 'server_url';
  static const _defaultUrl = 'http://192.168.18.220:8082';

  static String _baseUrl = _defaultUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_key) ?? _defaultUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _baseUrl = trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _baseUrl);
  }

  static String get apiUrl => '$_baseUrl/api';
  static String get wsUrl => _baseUrl.replaceFirst('http', 'ws');
}
