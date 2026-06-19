import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../config/server_config.dart';
import '../providers/auth_provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _serverUrl = ServerConfig.baseUrl;
  bool _testing = false;
  bool _tested = false;
  bool _connected = false;

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: '$_serverUrl/api',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      await dio.get('/health');
      await ServerConfig.setBaseUrl(_serverUrl);
      if (mounted) {
        setState(() { _testing = false; _tested = true; _connected = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conectado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _testing = false; _tested = true; _connected = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha na conexão'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Usuário não encontrado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              user.nomeCompleto.isNotEmpty ? user.nomeCompleto[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.nomeCompleto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (user.cargo != null) ...[
            const SizedBox(height: 4),
            Text(user.cargo!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                _InfoTile(icon: Icons.email, label: 'Email', value: user.email ?? 'Não informado'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.phone, label: 'Telefone', value: user.telefone ?? 'Não informado'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.badge, label: 'Cargo', value: user.cargo ?? 'Não informado'),
                const Divider(height: 1),
                _InfoTile(icon: Icons.verified_user, label: 'Status', value: user.ativo ? 'Ativo' : 'Inativo'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Servidor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _serverUrl,
                    decoration: const InputDecoration(
                      labelText: 'URL do Servidor',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                      hintText: 'http://192.168.0.145:8082',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (v) => _serverUrl = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testing ? null : _testConnection,
                          icon: _testing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_find),
                          label: const Text('Testar Conexão'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _connected ? Colors.green : (_tested ? Colors.red : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _connected ? 'Conectado' : (_tested ? 'Falha' : 'Não testado'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Sair'),
                            content: const Text('Deseja realmente sair?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await auth.logout();
                          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Sair da conta', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value),
    );
  }
}
