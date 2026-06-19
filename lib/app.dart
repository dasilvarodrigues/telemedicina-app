import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/teleconsulta_screen.dart';
import 'screens/fila_screen.dart';
import 'screens/prescricao_screen.dart';
import 'screens/prescricao_form_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/agendamentos_screen.dart';
import 'screens/patient_dashboard_screen.dart';


class TelemedicinaApp extends StatelessWidget {
  const TelemedicinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telemedicina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const _SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/fila':
            return MaterialPageRoute(builder: (_) => const FilaScreen());
          case '/prescricoes':
            return MaterialPageRoute(builder: (_) => const PrescricaoListScreen());
          case '/prescricao/nova':
            return MaterialPageRoute(
              builder: (_) {
                final args = settings.arguments as Map<String, dynamic>?;
                return PrescricaoFormScreen(
                  teleconsultaId: args?['teleconsulta_id'] as int?,
                  pacienteId: args?['paciente_id'] as int?,
                );
              },
              settings: settings,
            );
          case '/historico':
            return MaterialPageRoute(builder: (_) => const HistoricoScreen());
          case '/perfil':
            return MaterialPageRoute(builder: (_) => const PerfilScreen());
          case '/agendamentos':
            return MaterialPageRoute(builder: (_) => const AgendamentosScreen());
          case '/teleconsulta/novo':
            return MaterialPageRoute(
              builder: (_) => const TeleconsultaScreen(),
              settings: settings,
            );
          case '/patient-dashboard':
            return MaterialPageRoute(builder: (_) => const PatientDashboardScreen());
          default:
            if (settings.name?.startsWith('/prescricao/') == true) {
              final id = int.tryParse(settings.name!.split('/').last) ?? 0;
              final auth = context.watch<AuthProvider>();
              return MaterialPageRoute(
                builder: (_) => PrescricaoDetailScreen(
                  prescricaoId: id,
                  isMedico: auth.isMedico,
                ),
              );
            }
            if (settings.name?.startsWith('/teleconsulta/') == true) {
              final id = int.tryParse(settings.name!.split('/').last);
              return MaterialPageRoute(
                builder: (_) => TeleconsultaScreen(consultaId: id),
                settings: settings,
              );
            }
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;

    String route;
    if (auth.status == AuthStatus.authenticated) {
      route = auth.isMedico ? '/home' : '/patient-dashboard';
    } else {
      route = '/login';
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
