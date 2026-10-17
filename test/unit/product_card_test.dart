import 'package:appcaixaauto/src/Widget/product_card.dart';
import 'package:appcaixaauto/src/model/produto_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProdutoModel criaProduto({bool status = true, int quantidade = 5, double preco = 9.9}) {
  return ProdutoModel(
    id: 1,
    nome: 'Coca-Cola 2L',
    descricao: 'Refrigerante gelado',
    categoria: 'Bebidas',
    codigo: '123',
    foto: 'coca',
    peso: 2,
    pesoTolerancia: 0.1,
    preco: preco,
    quantidade: quantidade,
    status: status,
    unidadeMedida: 'UN',
    createAt: '',
    updateAt: '',
  );
}

Future<void> monta(WidgetTester tester, ProdutoModel p) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: productCard(p)))),
  );
}

void main() {
  testWidgets('exibe nome, descrição e preço formatado', (tester) async {
    await monta(tester, criaProduto(preco: 9.9));

    expect(find.text('Coca-Cola 2L'), findsOneWidget);
    expect(find.text('Refrigerante gelado'), findsOneWidget);
    expect(find.text('R\$ 9.90'), findsOneWidget);
  });

  testWidgets('mostra "Disponível" em verde quando status é true', (tester) async {
    await monta(tester, criaProduto(status: true));

    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Indisponível'), findsNothing);
  });

  testWidgets('mostra "Indisponível" quando status é false', (tester) async {
    await monta(tester, criaProduto(status: false));

    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.text('Disponível'), findsNothing);
  });

  testWidgets('badge muda de cor conforme disponibilidade', (tester) async {
    Color corBadge() {
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final c in containers) {
        final d = c.decoration;
        if (d is BoxDecoration && (d.color == Colors.green || d.color == Colors.red)) {
          return d.color!;
        }
      }
      throw StateError('badge não encontrado');
    }

    await monta(tester, criaProduto(status: true));
    expect(corBadge(), Colors.green);

    await monta(tester, criaProduto(status: false));
    await tester.pump();
    expect(corBadge(), Colors.red);
  });

  testWidgets('mostra ícone de fallback quando a imagem falha', (tester) async {
    await monta(tester, criaProduto());
    await tester.pump(); // deixa o errorBuilder rodar

    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
  });
}
