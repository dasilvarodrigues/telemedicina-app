class FilaPaciente {
  final int id;
  final int filaVirtualId;
  final int pacienteId;
  final int posicao;
  final String status;
  final DateTime entrouEm;
  final DateTime? chamadoEm;
  final Map<String, dynamic>? paciente;

  FilaPaciente({
    required this.id,
    required this.filaVirtualId,
    required this.pacienteId,
    required this.posicao,
    required this.status,
    required this.entrouEm,
    this.chamadoEm,
    this.paciente,
  });

  bool get isAguardando => status == 'aguardando';
  bool get isChamando => status == 'chamando';

  factory FilaPaciente.fromJson(Map<String, dynamic> json) => FilaPaciente(
    id: json['id'],
    filaVirtualId: json['fila_virtual_id'],
    pacienteId: json['paciente_id'],
    posicao: json['posicao'] ?? 0,
    status: json['status'] ?? 'aguardando',
    entrouEm: DateTime.parse(json['entrou_em'] ?? DateTime.now().toIso8601String()),
    chamadoEm: json['chamado_em'] != null ? DateTime.parse(json['chamado_em']) : null,
    paciente: json['paciente'],
  );
}
