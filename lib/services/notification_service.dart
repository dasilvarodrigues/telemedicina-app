import 'package:dio/dio.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _client;

  NotificationService(this._client);

  Future<void> registerDevice(String deviceToken, String platform) async {
    try {
      await _client.post('/devices', data: {
        'device_token': deviceToken,
        'platform': platform,
        'device_name': 'Flutter Mobile',
      });
    } on DioException catch (_) {}
  }

  Future<void> unregisterDevice(String deviceToken) async {
    try {
      await _client.delete('/devices/$deviceToken');
    } on DioException catch (_) {}
  }
}
