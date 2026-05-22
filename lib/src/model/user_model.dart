class UserModel {
  final String userId;
  final String nome;
  final String nomeCompleto;
  final String email;
  final String senha;
  final String cpf;
  final String telefone;
  final String dataNascimento;
  final String foto;
  final String emailVerificado;
  final String role;
   String? token;

  UserModel({
    required this.userId,
    required this.nome,
    required this.nomeCompleto,
    required this.email,
    required this.senha,
    required this.cpf,
    required this.telefone,
    required this.dataNascimento,
    required this.foto,
    required this.emailVerificado,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      nome: json['nome'] ?? '',
      nomeCompleto: json['nome_completo'] ?? '',
      email: json['email'] ?? '',
      senha: json['senha'] ?? '',
      cpf: json['cpf'] ?? '',
      telefone: json['telefone'] ?? '',
      dataNascimento: json['data_nascimento'] ?? '',
      foto: json['foto'] ?? '',
      emailVerificado: json['emailVerificado'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nome': nome,
      'nome_completo': nomeCompleto,
      'email': email,
      'senha': senha,
      'cpf': cpf,
      'telefone': telefone,
      'data_nascimento': dataNascimento,
      'foto': foto,
      'emailVerificado': emailVerificado,
      'role': role,
      'token': token,
    };
  }

  UserModel copyWith({
    String? userId,
    String? nome,
    String? nomeCompleto,
    String? email,
    String? senha,
    String? cpf,
    String? telefone,
    String? dataNascimento,
    String? foto,
    String? emailVerificado,
    String? role,
    String? token,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      foto: foto ?? this.foto,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}
