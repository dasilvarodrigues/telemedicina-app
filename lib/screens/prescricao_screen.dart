import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/auth_provider.dart';
import '../models/prescricao.dart';
import '../services/api_client.dart';
import '../services/prescricao_service.dart';

class PrescricaoListScreen extends StatelessWidget {
  const PrescricaoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final service = PrescricaoService(ApiClient());
    final isMedico = auth.isMedico;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          if (isMedico)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, '/prescricao/nova'),
            ),
        ],
      ),
      body: FutureBuilder<List<Prescricao>>(
        future: isMedico ? service.getHistory() : service.getPatientHistory(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          final prescricoes = snapshot.data ?? [];
          if (prescricoes.isEmpty) return const Center(child: Text('Nenhuma receita'));
          return ListView.builder(
            itemCount: prescricoes.length,
            itemBuilder: (_, i) {
              final p = prescricoes[i];
              final nome = isMedico
                  ? (p.paciente?['nome_completo'] ?? 'Paciente')
                  : (p.medico?['nome_completo'] ?? 'Médico');
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.isAssinada ? Colors.green : Colors.orange,
                    child: Icon(p.isAssinada ? Icons.verified : Icons.edit, color: Colors.white),
                  ),
                  title: Text(nome),
                  subtitle: Text('${p.medicamentos.length} medicamento(s) - ${_statusLabel(p.status)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/prescricao/${p.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assinada': return 'Assinada';
      case 'enviada': return 'Enviada';
      case 'rascunho': return 'Rascunho';
      default: return status;
    }
  }
}

class PrescricaoDetailScreen extends StatefulWidget {
  final int prescricaoId;
  final bool isMedico;
  const PrescricaoDetailScreen({super.key, required this.prescricaoId, this.isMedico = false});

  @override
  State<PrescricaoDetailScreen> createState() => _PrescricaoDetailScreenState();
}

class _PrescricaoDetailScreenState extends State<PrescricaoDetailScreen> {
  final service = PrescricaoService(ApiClient());
  Prescricao? _prescricao;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final p = await service.getPrescricao(widget.prescricaoId);
      if (mounted) setState(() { _prescricao = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = 'Erro ao carregar: $e'; _loading = false; });
    }
  }

  Future<void> _baixarPdf() async {
    try {
      final path = await ApiClient().downloadPdf(widget.prescricaoId);
      if (!mounted) return;
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir PDF: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Prescrição')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da Prescrição')),
        body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
    }

    final p = _prescricao!;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Prescrição')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(p.isAssinada ? Icons.verified : Icons.edit,
                          color: p.isAssinada ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Text(p.isAssinada ? 'Assinada' : 'Rascunho',
                          style: TextStyle(
                            color: p.isAssinada ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  if (p.assinadaEm != null) ...[
                    const SizedBox(height: 8),
                    Text('Assinada em: ${p.assinadaEm!.toLocal()}'),
                  ],
                ],
              ),
            ),
          ),
          if (p.conteudo.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Recomendações', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(p.conteudo),
          ],
          const SizedBox(height: 16),
          Text('Medicamentos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...p.medicamentos.map((m) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.nome} - ${m.dosagem}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Quantidade: ${m.quantidade}'),
                  Text(m.instrucoes),
                ],
              ),
            ),
          )),
        ],
      ),
      floatingActionButton: Builder(
        builder: (ctx) {
          final showAssinar = p.isRascunho && widget.isMedico;
          final podeBaixar = p.isAssinada;

          return FloatingActionButton.extended(
            onPressed: () async {
              if (showAssinar) {
                await service.assinar(widget.prescricaoId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prescrição assinada!')),
                  );
                }
                _load();
              } else if (podeBaixar) {
                await _baixarPdf();
              }
            },
            icon: Icon(showAssinar ? Icons.edit : Icons.download),
            label: Text(showAssinar ? 'Assinar' : 'Download PDF'),
          );
        },
      ),
    );
  }
}
