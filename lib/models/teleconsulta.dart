class Teleconsulta {
  final int id;
  final String uuid;
  final int pacienteId;
  final int medicoId;
  final int? agendamentoId;
  final String roomName;
  final String status;
  final DateTime? iniciadaEm;
  final DateTime? finalizadaEm;
  final DateTime? createdAt;
  final String? recordingUrl;
  final String? pacienteNome;
  final String? medicoNome;

  Teleconsulta({
    required this.id,
    required this.uuid,
    required this.pacienteId,
    required this.medicoId,
    this.agendamentoId,
    required this.roomName,
    required this.status,
    this.iniciadaEm,
    this.finalizadaEm,
    this.createdAt,
    this.recordingUrl,
    this.pacienteNome,
    this.medicoNome,
  });

  bool get isAtiva => status == 'ativa';
  bool get isFinalizada => status == 'finalizada' || status == 'gravada';

  factory Teleconsulta.fromJson(Map<String, dynamic> json) {
    String? extrairNome(dynamic obj) {
      if (obj is Map<String, dynamic>) return obj['nome_completo'] as String?;
      return null;
    }

    return Teleconsulta(
      id: json['id'],
      uuid: json['uuid'] ?? '',
      pacienteId: json['paciente_id'],
      medicoId: json['medico_id'],
      agendamentoId: json['agendamento_id'],
      roomName: json['room_name'] ?? '',
      status: json['status'] ?? 'agendada',
      iniciadaEm: json['iniciada_em'] != null ? DateTime.parse(json['iniciada_em']) : null,
      finalizadaEm: json['finalizada_em'] != null ? DateTime.parse(json['finalizada_em']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      recordingUrl: json['recording_url'],
      pacienteNome: extrairNome(json['paciente']),
      medicoNome: extrairNome(json['medico']),
    );
  }
}
