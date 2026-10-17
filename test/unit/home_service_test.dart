import 'dart:convert';

import 'package:appcaixaauto/src/service/HomeService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> produto(int id, String nome, int qtd, {bool status = true}) => {
      'id': id,
      'nome': nome,
      'descricao': 'desc $nome',
      'categoria': 'Mercado',
      'codigo': '000$id',
      'foto': 'foto$id',
      'peso': 1.0,
      'pesoTolerancia': 0.1,
      'preco': 5.5,
      'quantidade': qtd,
      'status': status,
      'unidadeMedida': 'UN',
      'createAt': '',
      'updateAt': '',
    };

/// Executa [body] com um cliente HTTP falso (HomeService usa http.get global).
Future<T> comApi<T>(
  Future<http.Response> Function(http.Request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=http://api.teste');
  });

  group('HomeService.getDestaques', () {
    test('retorna lista de produtos com quantidade em estoque', () async {
      final lista = await comApi(
        (req) async => http.Response(
          jsonEncode({
            'destaques': [produto(1, 'Arroz', 30), produto(2, 'Feijão', 0)],
          }),
          200,
        ),
        () => HomeService().getDestaques(),
      );

      expect(lista.length, 2);
      expect(lista[0].nome, 'Arroz');
      expect(lista[0].quantidade, 30);
      expect(lista[1].quantidade, 0);
    });

    test('chama a URL correta com Content-Type JSON', () async {
      late http.Request capturada;

      await comApi(
        (req) async {
          capturada = req;
          return http.Response(jsonEncode({'destaques': []}), 200);
        },
        () => HomeService().getDestaques(),
      );

      expect(capturada.method, 'GET');
      expect(capturada.url.toString(), 'http://api.teste/produtos/home');
      expect(capturada.headers['Content-Type'], 'application/json');
    });

    test('retorna lista vazia quando não há destaques', () async {
      final lista = await comApi(
        (_) async => http.Response(jsonEncode({'destaques': []}), 200),
        () => HomeService().getDestaques(),
      );
      expect(lista, isEmpty);
    });

    test('lança exceção quando status != 200', () async {
      expect(
        comApi(
          (_) async => http.Response('erro', 500),
          () => HomeService().getDestaques(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('lança exceção quando o JSON é inválido', () async {
      expect(
        comApi(
          (_) async => http.Response('não é json', 200),
          () => HomeService().getDestaques(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('lança exceção quando a chave "destaques" não existe', () async {
      expect(
        comApi(
          (_) async => http.Response(jsonEncode({'outro': []}), 200),
          () => HomeService().getDestaques(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('lança exceção em falha de rede', () async {
      expect(
        comApi(
          (_) async => throw http.ClientException('sem rede'),
          () => HomeService().getDestaques(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
