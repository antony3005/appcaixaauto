import 'package:appcaixaauto/src/model/produto_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> jsonProduto({int quantidade = 10}) => {
      'id': 1,
      'nome': 'Coca-Cola 2L',
      'descricao': 'Refrigerante',
      'categoria': 'Bebidas',
      'codigo': '7894900011517',
      'foto': 'coca',
      'peso': 2.1,
      'pesoTolerancia': 0.05,
      'preco': 9.9,
      'quantidade': quantidade,
      'status': true,
      'unidadeMedida': 'UN',
      'createAt': '2026-01-01',
      'updateAt': '2026-01-02',
    };

void main() {
  group('ProdutoModel.fromJson', () {
    test('converte todos os campos corretamente', () {
      final p = ProdutoModel.fromJson(jsonProduto(quantidade: 25));

      expect(p.id, 1);
      expect(p.nome, 'Coca-Cola 2L');
      expect(p.categoria, 'Bebidas');
      expect(p.codigo, '7894900011517');
      expect(p.preco, 9.9);
      expect(p.quantidade, 25);
      expect(p.status, true);
    });

    test('aceita quantidade zero (produto sem estoque)', () {
      final p = ProdutoModel.fromJson(jsonProduto(quantidade: 0));
      expect(p.quantidade, 0);
    });

    test('usa valores padrão quando campos estão ausentes', () {
      final p = ProdutoModel.fromJson({});

      expect(p.id, 0);
      expect(p.nome, '');
      expect(p.quantidade, 0);
      expect(p.preco, 0.0);
      expect(p.peso, 0.0);
      expect(p.status, false);
    });

    test('usa padrão quando campos são null', () {
      final p = ProdutoModel.fromJson({'quantidade': null, 'preco': null});
      expect(p.quantidade, 0);
      expect(p.preco, 0.0);
    });

    test('converte preço e peso inteiros para double', () {
      final p = ProdutoModel.fromJson({'preco': 10, 'peso': 2});
      expect(p.preco, 10.0);
      expect(p.preco, isA<double>());
      expect(p.peso, isA<double>());
    });

    test('quantidade vinda como String gera erro (documenta comportamento)', () {
      // O model faz `json['quantidade'] ?? 0` sem conversão: String quebra.
      expect(
        () => ProdutoModel.fromJson({'quantidade': '5'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ProdutoModel.toJson', () {
    test('gera mapa com os mesmos dados de entrada', () {
      final json = jsonProduto(quantidade: 7);
      expect(ProdutoModel.fromJson(json).toJson(), json);
    });

    test('ida e volta (fromJson -> toJson -> fromJson) preserva estoque', () {
      final original = ProdutoModel.fromJson(jsonProduto(quantidade: 42));
      final copia = ProdutoModel.fromJson(original.toJson());
      expect(copia.quantidade, 42);
      expect(copia.nome, original.nome);
    });
  });

  group('ProdutoModel.copyWith', () {
    final base = ProdutoModel.fromJson(jsonProduto(quantidade: 10));

    test('altera apenas a quantidade e mantém o resto', () {
      final novo = base.copyWith(quantidade: 3);

      expect(novo.quantidade, 3);
      expect(novo.nome, base.nome);
      expect(novo.preco, base.preco);
      expect(novo.id, base.id);
    });

    test('não altera o objeto original (imutabilidade)', () {
      base.copyWith(quantidade: 99);
      expect(base.quantidade, 10);
    });

    test('sem argumentos devolve cópia equivalente', () {
      final copia = base.copyWith();
      expect(copia.toJson(), base.toJson());
      expect(identical(copia, base), false);
    });

    test('permite zerar o estoque', () {
      expect(base.copyWith(quantidade: 0).quantidade, 0);
    });

    test('simula baixa de estoque após venda', () {
      const vendido = 4;
      final depois = base.copyWith(quantidade: base.quantidade - vendido);
      expect(depois.quantidade, 6);
    });
  });
}
