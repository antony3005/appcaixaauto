import 'dart:convert';

import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const session = AuthSession(
    token: 'jwt-global',
    user: ClientUser(
      id: 'user-global',
      firstName: 'Maria',
      lastName: 'Silva',
      email: 'maria@example.test',
      cpf: '52998224725',
      phone: '',
    ),
  );

  test('envia somente convite e troca JWT após LINKED', () async {
    late http.Request captured;
    final repository = _repository((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'LINKED',
          'accessToken': 'jwt-linked',
          'empresaId': 'server-only',
          'condominioId': 'server-only',
          'cpfVerificationStatus': 'VERIFIED',
          'historicalPurchasesClaimed': true,
        }),
        200,
      );
    });

    final linked = await repository.linkTenant(session, ' opaque-invite ');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/app-cliente/tenant-link');
    expect(captured.headers['Authorization'], 'Bearer jwt-global');
    expect(jsonDecode(captured.body), {'token': 'opaque-invite'});
    expect(captured.body, isNot(contains('empresaId')));
    expect(captured.body, isNot(contains('condominioId')));
    expect(captured.body, isNot(contains('cpf')));
    expect(linked.token, 'jwt-linked');
    expect(linked.user, same(session.user));
  });

  test('convite inválido tem mensagem opaca e amigável', () async {
    final repository = _repository(
      (_) async => http.Response(
        '{"code":"TENANT_INVITATION_INVALID","message":"technical"}',
        404,
      ),
    );

    await expectLater(
      repository.linkTenant(session, 'invalid'),
      throwsA(
        isA<AppException>()
            .having((error) => error.code, 'code', 'TENANT_INVITATION_INVALID')
            .having((error) => error.message, 'message', contains('inválido')),
      ),
    );
  });

  test('resposta sem novo JWT é recusada', () async {
    final repository = _repository(
      (_) async => http.Response('{"status":"LINKED"}', 200),
    );

    await expectLater(
      repository.linkTenant(session, 'invite'),
      throwsA(isA<AppException>()),
    );
  });
}

ClientApiRepository _repository(
  Future<http.Response> Function(http.Request) handler,
) => ClientApiRepository(
  config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
  client: MockClient(handler),
);
