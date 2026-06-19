import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/fila_provider.dart';
import '../widgets/queue_position_widget.dart';

class FilaScreen extends StatefulWidget {
  const FilaScreen({super.key});

  @override
  State<FilaScreen> createState() => _FilaScreenState();
}

class _FilaScreenState extends State<FilaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FilaProvider>().loadFilas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filaProvider = context.watch<FilaProvider>();
    final auth = context.watch<AuthProvider>();
    final isMedico = auth.isMedico;

    return Scaffold(
      appBar: AppBar(title: const Text('Fila Virtual')),
      body: RefreshIndicator(
        onRefresh: () => filaProvider.loadFilas(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isMedico && auth.user != null)
              QueuePositionWidget(pacienteId: auth.user!.id),
            const SizedBox(height: 16),
            Text('Filas Abertas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...filaProvider.filas.map((fila) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: fila.isAberta ? Colors.green : Colors.grey,
                  child: Text('${fila.pacientesAguardando}', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(fila.tipo == 'especialidade' ? 'Especialidade' : 'Médico(a)'),
                subtitle: Text('${fila.pacientesAguardando} paciente(s)'),
                trailing: isMedico
                    ? PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'pacientes') {
                            await filaProvider.loadPacientes(fila.id);
                            if (mounted) _mostrarPacientes(filaProvider, fila.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'pacientes', child: Text('Ver pacientes')),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          await filaProvider.entrarFila(fila.id, auth.user!.id);
                        },
                        child: const Text('Entrar'),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _mostrarPacientes(FilaProvider provider, int filaId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Pacientes na fila', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...provider.pacientes.map((p) => ListTile(
            leading: CircleAvatar(child: Text('${p.posicao}')),
            title: Text(p.paciente?['nome_completo'] ?? 'Paciente'),
            subtitle: Text(p.status),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.isChamando)
                  TextButton(
                    onPressed: () => provider.atender(filaId, p.id),
                    child: const Text('Atender'),
                  ),
                if (p.isChamando)
                  TextButton(
                    onPressed: () => provider.marcarAusente(filaId, p.id),
                    child: const Text('Ausente'),
                  ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.chamarProximo(filaId),
            child: const Text('Chamar Próximo'),
          ),
        ],
      ),
    );
  }
}
