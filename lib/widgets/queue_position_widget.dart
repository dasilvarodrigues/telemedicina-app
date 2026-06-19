import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fila_provider.dart';

class QueuePositionWidget extends StatefulWidget {
  final int pacienteId;

  const QueuePositionWidget({super.key, required this.pacienteId});

  @override
  State<QueuePositionWidget> createState() => _QueuePositionWidgetState();
}

class _QueuePositionWidgetState extends State<QueuePositionWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FilaProvider>().carregarMinhaPosicao(widget.pacienteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fila = context.watch<FilaProvider>();
    final posicao = fila.minhaPosicao;

    if (posicao == null || posicao['na_fila'] == false) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Sua posição na fila', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '${posicao['posicao']}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Text('de ${posicao['total']} paciente(s)'),
            const SizedBox(height: 8),
            Text('Status: ${posicao['status']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final filaId = posicao['fila_id'] as int?;
                if (filaId == null) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sair da fila?'),
                    content: const Text('Você perderá sua posição na fila.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sair')),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  context.read<FilaProvider>().sairFila(filaId, widget.pacienteId);
                }
              },
              child: const Text('Sair da fila'),
            ),
          ],
        ),
      ),
    );
  }
}
