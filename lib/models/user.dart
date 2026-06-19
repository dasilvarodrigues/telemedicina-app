class User {
  final int id;
  final String nomeCompleto;
  final String? email;
  final String? telefone;
  final int roleId;
  final String? cargo;
  final bool ativo;

  User({
    required this.id,
    required this.nomeCompleto,
    this.email,
    this.telefone,
    required this.roleId,
    this.cargo,
    this.ativo = true,
  });

  bool get isMedico => roleId == 2;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    nomeCompleto: json['nome_completo'] ?? '',
    email: json['email'],
    telefone: json['telefone'],
    roleId: json['role_id'] ?? 4,
    cargo: json['cargo'],
    ativo: json['ativo'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome_completo': nomeCompleto,
    'email': email,
    'telefone': telefone,
    'role_id': roleId,
    'cargo': cargo,
    'ativo': ativo,
  };
}
