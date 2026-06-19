// telemedicina-app/lib/config/api_config.dart
import 'server_config.dart';

class ApiConfig {
  static String get baseUrl => ServerConfig.apiUrl;
  static String get wsUrl => ServerConfig.wsUrl;
  static const Duration timeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
}
