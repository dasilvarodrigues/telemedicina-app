import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/server_config.dart';
import 'providers/auth_provider.dart';
import 'providers/teleconsulta_provider.dart';
import 'providers/fila_provider.dart';
import 'services/api_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ServerConfig.init();
  } catch (_) {
    // Uses default URL if SharedPreferences fails
  }

  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => TeleconsultaProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => FilaProvider(apiClient)),
      ],
      child: const TelemedicinaApp(),
    ),
  );
}
