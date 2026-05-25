class ProdutoModel {
  final int id;
  final String nome;
  final String descricao;
  final String categoria;
  final String codigo;
  final String foto;
  final double peso;
  final double pesoTolerancia;
  final double preco;
  final int quantidade;
  final bool status;
  final String unidadeMedida;
  final String createAt;
  final String updateAt;

  ProdutoModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.codigo,
    required this.foto,
    required this.peso,
    required this.pesoTolerancia,
    required this.preco,
    required this.quantidade,
    required this.status,
    required this.unidadeMedida,
    required this.createAt,
    required this.updateAt,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'] ?? 0,
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      foto: json['foto']?.toString() ?? '',
      peso: (json['peso'] ?? 0).toDouble(),
      pesoTolerancia: (json['pesoTolerancia'] ?? 0).toDouble(),
      preco: (json['preco'] ?? 0).toDouble(),
      quantidade: json['quantidade'] ?? 0,
      status: json['status'] ?? false,
      unidadeMedida: json['unidadeMedida']?.toString() ?? '',
      createAt: json['createAt']?.toString() ?? '',
      updateAt: json['updateAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'codigo': codigo,
      'foto': foto,
      'peso': peso,
      'pesoTolerancia': pesoTolerancia,
      'preco': preco,
      'quantidade': quantidade,
      'status': status,
      'unidadeMedida': unidadeMedida,
      'createAt': createAt,
      'updateAt': updateAt,
    };
  }

  ProdutoModel copyWith({
    int? id,
    String? nome,
    String? descricao,
    String? categoria,
    String? codigo,
    String? foto,
    double? peso,
    double? pesoTolerancia,
    double? preco,
    int? quantidade,
    bool? status,
    String? unidadeMedida,
    String? createAt,
    String? updateAt,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      codigo: codigo ?? this.codigo,
      foto: foto ?? this.foto,
      peso: peso ?? this.peso,
      pesoTolerancia: pesoTolerancia ?? this.pesoTolerancia,
      preco: preco ?? this.preco,
      quantidade: quantidade ?? this.quantidade,
      status: status ?? this.status,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}
