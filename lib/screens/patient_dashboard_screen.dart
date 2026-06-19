import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, dynamic>? _nextAppointment;
  bool _loadingAppointment = true;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
  }

  Future<void> _loadNextAppointment() async {
    setState(() => _loadingAppointment = true);
    try {
      final client = ApiClient();
      final response = await client.get('/recepcao/hoje');
      final data = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

      _nextAppointment = data.cast<Map<String, dynamic>?>().firstWhere(
        (a) {
          final dh = a?['data_hora']?.toString() ?? '';
          return dh.startsWith(hoje) &&
              (a?['status'] == 'agendado' || a?['status'] == 'confirmado');
        },
        orElse: () => null,
      );
    } catch (_) {
      _nextAppointment = null;
    }
    if (mounted) setState(() => _loadingAppointment = false);
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy • HH:mm').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.nomeCompleto.split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $name'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNextAppointment,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildNextAppointmentCard(),
            const SizedBox(height: 24),
            Text('Serviços', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: break;
            case 1: Navigator.pushNamed(context, '/agendamentos');
            case 2: Navigator.pushNamed(context, '/fila');
            case 3: Navigator.pushNamed(context, '/perfil');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Consultas'),
          NavigationDestination(icon: Icon(Icons.queue), label: 'Fila'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard() {
    if (_loadingAppointment) {
      return const Card(
        child: SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_nextAppointment == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('Nenhuma consulta agendada', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/agendamentos'),
                icon: const Icon(Icons.add),
                label: const Text('Agendar agora'),
              ),
            ],
          ),
        ),
      );
    }

    final a = _nextAppointment!;
    final medico = a['medico']?['nome_completo'] ?? a['medico_nome'] ?? 'Médico';
    final especialidade = a['especialidade']?['nome'] ?? a['especialidade_nome'] ?? '';
    final dataHora = _formatDateTime(a['data_hora']?.toString());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('PRÓXIMA CONSULTA',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dataHora.isNotEmpty)
              _infoRow(Icons.calendar_today, dataHora),
            const SizedBox(height: 8),
            _infoRow(Icons.person, medico),
            if (especialidade.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.medical_services, especialidade),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/agendamentos'),
                icon: const Icon(Icons.info),
                label: const Text('Ver Agendamentos', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      _QuickAction(icon: Icons.videocam, label: 'Teleconsulta', color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/teleconsulta/novo')),
      _QuickAction(icon: Icons.science, label: 'Exames', color: Colors.teal,
        onTap: () {}),
      _QuickAction(icon: Icons.medication, label: 'Receitas', color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/prescricoes')),
      _QuickAction(icon: Icons.history, label: 'Histórico', color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/historico')),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _buildQuickActionCard(actions[i]),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: action.color.withValues(alpha: 0.08),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: action.color.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
