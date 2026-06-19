class PrescricaoMedicamento {
  final String nome;
  final String dosagem;
  final int quantidade;
  final String instrucoes;

  PrescricaoMedicamento({
    required this.nome,
    required this.dosagem,
    required this.quantidade,
    required this.instrucoes,
  });

  factory PrescricaoMedicamento.fromJson(Map<String, dynamic> json) => PrescricaoMedicamento(
    nome: json['nome'] ?? '',
    dosagem: json['dosagem'] ?? '',
    quantidade: json['quantidade'] ?? 0,
    instrucoes: json['instrucoes'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'dosagem': dosagem,
    'quantidade': quantidade,
    'instrucoes': instrucoes,
  };
}

class Prescricao {
  final int id;
  final String uuid;
  final int medicoId;
  final int pacienteId;
  final String conteudo;
  final List<PrescricaoMedicamento> medicamentos;
  final String status;
  final String? assinaturaHash;
  final DateTime? assinadaEm;
  final DateTime createdAt;
  final Map<String, dynamic>? medico;
  final Map<String, dynamic>? paciente;

  Prescricao({
    required this.id,
    required this.uuid,
    required this.medicoId,
    required this.pacienteId,
    required this.conteudo,
    required this.medicamentos,
    required this.status,
    this.assinaturaHash,
    this.assinadaEm,
    required this.createdAt,
    this.medico,
    this.paciente,
  });

  bool get isAssinada => status == 'assinada' || status == 'enviada';
  bool get isRascunho => status == 'rascunho';

  factory Prescricao.fromJson(Map<String, dynamic> json) => Prescricao(
    id: json['id'],
    uuid: json['uuid'] ?? '',
    medicoId: json['medico_id'],
    pacienteId: json['paciente_id'],
    conteudo: json['conteudo'] ?? '',
    medicamentos: (json['medicamentos'] as List?)
        ?.map((e) => PrescricaoMedicamento.fromJson(e))
        .toList() ?? [],
    status: json['status'] ?? 'rascunho',
    assinaturaHash: json['assinatura_hash'],
    assinadaEm: json['assinada_em'] != null ? DateTime.parse(json['assinada_em']) : null,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    medico: json['medico'],
    paciente: json['paciente'],
  );
}
