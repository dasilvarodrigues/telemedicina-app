import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMedico = auth.isMedico;

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${auth.user?.nomeCompleto.split(' ').first ?? ''}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Meu Perfil',
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isMedico) ...[
            _ActionCard(
              icon: Icons.calendar_month,
              label: 'Agendar Consulta',
              subtitle: 'Marque uma consulta com um médico',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/agendamentos'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.videocam,
              label: 'Videochamada',
              subtitle: 'Iniciar consulta por vídeo',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/teleconsulta/novo'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.queue_play_next,
              label: 'Fila de Atendimento',
              subtitle: 'Acompanhe sua posição na fila',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/fila'),
            ),
          ] else ...[
            _ActionCard(
              icon: Icons.videocam,
              label: 'Iniciar Teleconsulta',
              subtitle: 'Iniciar videochamada com paciente',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/teleconsulta/novo'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.calendar_month,
              label: 'Agenda',
              subtitle: 'Ver consultas agendadas',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/agendamentos'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.add_circle,
              label: 'Nova Prescrição',
              subtitle: 'Criar receita médica',
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, '/prescricao/nova'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.queue_play_next,
              label: 'Gerenciar Fila',
              subtitle: 'Chamar próximos pacientes',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/fila'),
            ),
          ],
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.description,
            label: 'Minhas Prescrições',
            subtitle: 'Visualizar receitas médicas',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/prescricoes'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.history,
            label: 'Histórico',
            subtitle: 'Consultas realizadas',
            color: Colors.indigo,
            onTap: () => Navigator.pushNamed(context, '/historico'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Consultas'),
          NavigationDestination(icon: Icon(Icons.queue), label: 'Fila'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 1: Navigator.pushNamed(context, '/agendamentos');
            case 2: Navigator.pushNamed(context, '/fila');
            case 3: Navigator.pushNamed(context, '/perfil');
          }
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
