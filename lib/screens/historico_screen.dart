import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/teleconsulta_provider.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeleconsultaProvider>().loadHistory();
    });
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'agendada': return Icons.schedule;
      case 'ativa': return Icons.videocam;
      case 'finalizada': return Icons.check_circle;
      case 'gravada': return Icons.cloud_done;
      default: return Icons.help;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'agendada': return Colors.orange;
      case 'ativa': return Colors.green;
      case 'finalizada': return Colors.blue;
      case 'gravada': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'agendada': return 'Agendada';
      case 'ativa': return 'Em andamento';
      case 'finalizada': return 'Finalizada';
      case 'gravada': return 'Gravada';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeleconsultaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Consultas')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadHistory(),
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? Center(child: Text('Erro: ${provider.error}'))
                : provider.history.isEmpty
                    ? const Center(child: Text('Nenhuma consulta encontrada'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.history.length,
                        itemBuilder: (_, i) {
                          final c = provider.history[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(c.status),
                                child: Icon(_statusIcon(c.status), color: Colors.white),
                              ),
                              title: Text('Consulta #${c.id}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_statusLabel(c.status)),
                                  if (c.pacienteNome != null)
                                    Text('Paciente: ${c.pacienteNome}',
                                        style: const TextStyle(fontSize: 12)),
                                  if (c.iniciadaEm != null)
                                    Text('${c.iniciadaEm!.day}/${c.iniciadaEm!.month}/${c.iniciadaEm!.year}',
                                        style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: c.recordingUrl != null
                                  ? IconButton(
                                      icon: const Icon(Icons.play_circle, color: Colors.blue),
                                      onPressed: () {/* open recording */},
                                    )
                                  : null,
                              onTap: c.isAtiva
                                  ? () => Navigator.pushNamed(context, '/teleconsulta/${c.id}')
                                  : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
