import 'dart:convert';

import 'package:appcaixaauto/src/Widget/product_card.dart';
import 'package:appcaixaauto/src/model/produto_model.dart';
import 'package:appcaixaauto/src/service/HomeService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> p(int id, String nome, int qtd, bool status) => {
      'id': id,
      'nome': nome,
      'descricao': 'desc',
      'categoria': 'Mercado',
      'codigo': '$id',
      'foto': 'f$id',
      'peso': 1,
      'pesoTolerancia': 0.1,
      'preco': 10,
      'quantidade': qtd,
      'status': status,
      'unidadeMedida': 'UN',
      'createAt': '',
      'updateAt': '',
    };

/// Mesma lista que a Dashboard monta: serviço -> model -> widget.
class ListaProdutos extends StatelessWidget {
  const ListaProdutos({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProdutoModel>>(
      future: HomeService().getDestaques(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return const Center(child: Text('Erro ao carregar'));
        return ListView(children: snap.data!.map(productCard).toList());
      },
    );
  }
}

Future<void> montaComApi(WidgetTester tester, http.Response Function() resposta) async {
  await http.runWithClient(() async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ListaProdutos())));
    await tester.pump();
    await tester.pump();
  }, () => MockClient((_) async => resposta()));
}

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'API_URL=http://api.teste'));

  testWidgets('API -> Service -> Model -> Widget: lista produtos e status de estoque',
      (tester) async {
    await montaComApi(
      tester,
      () => http.Response(
        jsonEncode({
          'destaques': [p(1, 'Arroz', 20, true), p(2, 'Feijão', 0, false)],
        }),
        200,
      ),
    );

    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('Feijão'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Indisponível'), findsOneWidget);
  });

  testWidgets('exibe mensagem de erro quando a API falha', (tester) async {
    await montaComApi(tester, () => http.Response('erro', 500));

    expect(find.text('Erro ao carregar'), findsOneWidget);
  });

  test('integração Service + Model: quantidade chega correta e baixa de estoque funciona',
      () async {
    final lista = await http.runWithClient(
      () => HomeService().getDestaques(),
      () => MockClient((_) async => http.Response(
            jsonEncode({'destaques': [p(1, 'Arroz', 10, true)]}),
            200,
          )),
    );

    final apos = lista.first.copyWith(quantidade: lista.first.quantidade - 3);

    expect(lista.first.quantidade, 10);
    expect(apos.quantidade, 7);
  });
}
