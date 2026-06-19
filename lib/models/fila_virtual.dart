class FilaVirtual {
  final int id;
  final String tipo;
  final int? especialidadeId;
  final int? medicoId;
  final String status;
  final int pacientesAguardando;

  FilaVirtual({
    required this.id,
    required this.tipo,
    this.especialidadeId,
    this.medicoId,
    required this.status,
    this.pacientesAguardando = 0,
  });

  bool get isAberta => status == 'aberta';

  factory FilaVirtual.fromJson(Map<String, dynamic> json) => FilaVirtual(
    id: json['id'],
    tipo: json['tipo'] ?? 'especialidade',
    especialidadeId: json['especialidade_id'],
    medicoId: json['medico_id'],
    status: json['status'] ?? 'fechada',
    pacientesAguardando: json['pacientes_aguardando'] ?? 0,
  );
}
