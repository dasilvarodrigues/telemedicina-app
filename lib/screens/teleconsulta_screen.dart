import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/teleconsulta.dart';
import '../providers/auth_provider.dart';
import '../providers/teleconsulta_provider.dart';
import '../widgets/video_call_widget.dart';

class TeleconsultaScreen extends StatefulWidget {
  final int? consultaId;
  const TeleconsultaScreen({super.key, this.consultaId});

  @override
  State<TeleconsultaScreen> createState() => _TeleconsultaScreenState();
}

class _TeleconsultaScreenState extends State<TeleconsultaScreen> {
  final _pacienteIdController = TextEditingController();
  int? _pacienteId;
  int? _agendamentoId;
  List<Teleconsulta> _ativas = [];
  bool _loadingAtivas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _pacienteId = args['paciente_id'] as int?;
          _agendamentoId = args['agendamento_id'] as int?;
          if (_pacienteId != null) {
            _pacienteIdController.text = _pacienteId.toString();
          }
        });
        if (widget.consultaId != null) {
          _entrarConsulta(widget.consultaId!);
        }
      } else if (widget.consultaId != null) {
        _entrarConsulta(widget.consultaId!);
      }
      if (_pacienteId == null && !auth.isMedico) {
        _pacienteIdController.text = auth.user!.id.toString();
      }
      if (!auth.isMedico) {
        _carregarAtivas();
      }
    });
  }

  Future<void> _carregarAtivas() async {
    setState(() => _loadingAtivas = true);
    try {
      final provider = context.read<TeleconsultaProvider>();
      await provider.loadActive();
      _ativas = provider.activeList;
      if (_ativas.isNotEmpty && mounted) {
        _entrarConsulta(_ativas.first.id);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAtivas = false);
  }

  @override
  void dispose() {
    _pacienteIdController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (cam.isGranted && mic.isGranted) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissões de câmera e microfone são necessárias')),
      );
    }
    return false;
  }

  Future<void> _entrarConsulta(int consultaId) async {
    if (!await _requestPermissions()) return;
    final provider = context.read<TeleconsultaProvider>();
    await provider.join(consultaId);
  }

  Future<void> _iniciarConsulta() async {
    if (!await _requestPermissions()) return;

    final pacienteId = _pacienteId ?? int.tryParse(_pacienteIdController.text);
    if (pacienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o ID do paciente')),
      );
      return;
    }

    final provider = context.read<TeleconsultaProvider>();
    await provider.create(pacienteId, agendamentoId: _agendamentoId);
  }

  Future<void> _encerrarConsulta() async {
    final provider = context.read<TeleconsultaProvider>();
    if (provider.currentConsulta != null) {
      await provider.end(provider.currentConsulta!.id);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeleconsultaProvider>();
    final auth = context.watch<AuthProvider>();

    if (provider.accessData != null) {
      return VideoCallWidget(
        accessData: provider.accessData!,
        onEnd: auth.isMedico ? _encerrarConsulta : null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teleconsulta'),
        actions: [
          if (provider.currentConsulta != null && auth.isMedico)
            IconButton(
              icon: const Icon(Icons.call_end, color: Colors.red),
              tooltip: 'Encerrar',
              onPressed: _encerrarConsulta,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (provider.currentConsulta != null) ...[
              Card(
                color: Colors.blue[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: provider.currentConsulta!.isAtiva ? Colors.green : Colors.orange,
                    child: Icon(
                      provider.currentConsulta!.isAtiva ? Icons.videocam : Icons.schedule,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('Consulta #${provider.currentConsulta!.id}'),
                  subtitle: Text('Status: ${provider.currentConsulta!.status}'),
                  trailing: provider.currentConsulta!.isAtiva
                      ? ElevatedButton.icon(
                          onPressed: () => provider.join(provider.currentConsulta!.id),
                          icon: const Icon(Icons.videocam, size: 16),
                          label: const Text('Entrar'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (auth.isMedico) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Nova Chamada', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pacienteIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID do Paciente',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: provider.loading ? null : _iniciarConsulta,
                          icon: provider.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.videocam),
                          label: const Text('Iniciar Videochamada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Minha Consulta', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      if (_loadingAtivas)
                        const Center(child: CircularProgressIndicator())
                      else if (_ativas.isEmpty)
                        Column(
                          children: [
                            Icon(Icons.videocam_off, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Nenhuma consulta ativa no momento',
                              style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      else ...[
                        for (final c in _ativas) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.videocam, color: Colors.white, size: 20),
                            ),
                            title: Text('Consulta #${c.id}'),
                            subtitle: Text(c.medicoNome ?? 'Médico'),
                            trailing: ElevatedButton.icon(
                              onPressed: () => _entrarConsulta(c.id),
                              icon: const Icon(Icons.login, size: 16),
                              label: const Text('Entrar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          if (c != _ativas.last) const Divider(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
