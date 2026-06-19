import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  List<Map<String, dynamic>> _agendamentos = [];
  bool _loading = true;
  String _filter = 'todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = ApiClient();
      final response = await client.get('/recepcao/hoje');
      if (mounted) setState(() {
        _agendamentos = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_filter == 'todos') return _agendamentos;
    return _agendamentos.where((a) => a['status'] == _filter).toList();
  }


  Color _statusColor(String status) {
    switch (status) {
      case 'agendado': return Colors.blue;
      case 'confirmado': return Colors.green;
      case 'em_atendimento': return Colors.orange;
      case 'realizado': return Colors.teal;
      case 'cancelado': return Colors.red;
      case 'nao_compareceu': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'agendado': return 'Agendado';
      case 'confirmado': return 'Confirmado';
      case 'em_atendimento': return 'Em Atendimento';
      case 'realizado': return 'Realizado';
      case 'cancelado': return 'Cancelado';
      case 'nao_compareceu': return 'Não compareceu';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMedico = auth.isMedico;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip('todos', 'Todos'),
                  const SizedBox(width: 8),
                  _FilterChip('agendado', 'Agendado'),
                  const SizedBox(width: 8),
                  _FilterChip('confirmado', 'Confirmado'),
                  const SizedBox(width: 8),
                  _FilterChip('cancelado', 'Cancelado'),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Center(child: Text('Nenhuma consulta encontrada',
                                style: TextStyle(color: Colors.grey))),

                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredList.length,
                          itemBuilder: (_, i) {
                            final a = _filteredList[i];
                            final pacienteNome = a['paciente']?['nome_completo'] ?? 'Paciente';
                            final especialidadeNome = a['especialidade']?['nome'] ?? '';
                            final dataHora = a['data_hora'] != null
                                ? _formatDateTime(a['data_hora'].toString())
                                : '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(a['status'] ?? ''),
                                  child: Text(
                                    pacienteNome.isNotEmpty ? pacienteNome[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(pacienteNome, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (especialidadeNome.isNotEmpty)
                                      Text(especialidadeNome, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(a['status'] ?? '').withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _statusLabel(a['status'] ?? ''),
                                            style: TextStyle(fontSize: 11, color: _statusColor(a['status'] ?? '')),
                                          ),
                                        ),
                                        if (dataHora.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 2),
                                          Text(dataHora,
                                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: isMedico && a['status'] == 'agendado'
                                    ? PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          final client = ApiClient();
                                          try {
                                            await client.post('/recepcao/agendamentos/${a['id']}/$v');
                                            _load();
                                          } catch (e) {
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erro: $e')),
                                            );
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'confirmar', child: Text('Confirmar')),
                                          const PopupMenuItem(value: 'cancelar', child: Text('Cancelar')),
                                        ],
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),

    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (_) {
      return dateTimeStr.length >= 16 ? dateTimeStr.substring(0, 16) : dateTimeStr;
    }
  }

  Widget _FilterChip(String value, String label) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

}
