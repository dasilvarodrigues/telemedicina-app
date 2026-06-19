import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../config/server_config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final route = auth.isMedico ? '/home' : '/patient-dashboard';
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (e) {
      setState(() => _error = 'Email ou senha inválidos');
    }
  }

  void _showServerConfig() {
    String url = ServerConfig.baseUrl;
    bool testing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Configurar Servidor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: url),
                decoration: const InputDecoration(
                  labelText: 'URL do Servidor',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                  hintText: 'http://192.168.0.145:8082',
                ),
                keyboardType: TextInputType.url,
                onChanged: (v) => url = v,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: testing
                      ? null
                      : () async {
                          setDialogState(() => testing = true);
                          try {
                            final dio = Dio(BaseOptions(
                              baseUrl: '${url.trim()}/api',
                              connectTimeout: const Duration(seconds: 5),
                              receiveTimeout: const Duration(seconds: 5),
                            ));
                            await dio.get('/health');
                            await ServerConfig.setBaseUrl(url.trim());
                            if (ctx.mounted) {
                              setDialogState(() => testing = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Conectado!'), backgroundColor: Colors.green),
                              );
                              Navigator.pop(ctx);
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              setDialogState(() => testing = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Falha na conexão'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  icon: testing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find),
                  label: const Text('Testar e Salvar'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Configurar Servidor',
                      onPressed: _showServerConfig,
                    ),
                  ),
                  Image.asset('assets/images/logo.png', height: 96, width: 96, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text('Telemedicina', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Acesse sua conta', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock)),
                    obscureText: true,
                    validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Consumer<AuthProvider>(
                      builder: (_, auth, __) => ElevatedButton(
                        onPressed: auth.status == AuthStatus.loading ? null : _login,
                        child: auth.status == AuthStatus.loading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Entrar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
