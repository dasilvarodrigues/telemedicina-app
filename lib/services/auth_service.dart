import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<User> login(String email, String password) async {
    try {
      final response = await Dio().post(
        '${ApiConfig.baseUrl}/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      await _client.setToken(data['token']);
      return User.fromJson(data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } catch (_) {
      // ignore logout errors
    }
    await _client.clearToken();
  }

  Future<User> getUser() async {
    try {
      final response = await _client.get('/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _client.getToken();
    return token != null;
  }

  Exception _handleError(DioException e) {
    final message = e.response?.data['message'] ?? 'Erro de autenticação';
    return Exception(message);
  }
}
