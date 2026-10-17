import 'dart:async';
import 'dart:convert';

import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const request = ClientRegistrationRequest(
    firstName: 'Maria',
    lastName: 'da Silva',
    cpf: '52998224725',
    email: 'maria@email.com',
    phone: '75999999999',
    password: 'segredo',
  );

  test('DTO envia somente campos pessoais do contrato auditado', () {
    expect(request.toJson(), {
      'nome': 'Maria',
      'sobrenome': 'da Silva',
      'email': 'maria@email.com',
      'senha': 'segredo',
      'cpf': '52998224725',
      'telefone': '75999999999',
    });
    expect(request.toJson(), isNot(contains('role')));
    expect(request.toJson(), isNot(contains('roleUser')));
    expect(request.toJson(), isNot(contains('empresaId')));
    expect(request.toJson(), isNot(contains('condominioId')));
  });

  test('201 chama /auth/register sem JWT e conclui', () async {
    late http.Request captured;
    final repository = _repository((incoming) async {
      captured = incoming;
      return http.Response('{"requiresLogin":true}', 201);
    });

    await repository.registerClient(request);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/auth/register');
    expect(captured.headers, isNot(contains('authorization')));
    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(sent, isNot(contains('empresaId')));
    expect(sent, isNot(contains('condominioId')));
    expect(sent, isNot(contains('role')));
  });

  test('configuração legal pública é lida antes do cadastro', () async {
    late http.Request captured;
    final repository = _repository((incoming) async {
      captured = incoming;
      return http.Response(
        jsonEncode({
          'termsUrl': 'https://example.test/termos',
          'privacyUrl': 'https://example.test/privacidade',
          'termsVersion': '2026-09',
          'privacyVersion': '2026-08',
          'legalDocumentsConfigured': true,
        }),
        200,
      );
    });

    final config = await repository.loadRegistrationLegalConfig();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/public/app-config');
    expect(captured.headers, isNot(contains('authorization')));
    expect(config.configured, isTrue);
    expect(config.termsVersion, '2026-09');
    expect(config.privacyVersion, '2026-08');
  });

  test('cadastro envia aceite e versões que vieram da configuração', () async {
    late http.Request captured;
    final legalRequest = ClientRegistrationRequest.fromForm(
      fullName: 'Maria da Silva',
      cpf: '52998224725',
      email: 'maria@email.com',
      phone: '',
      password: 'segredo',
      legalConfig: RegistrationLegalConfig(
        termsUrl: Uri.parse('https://example.test/termos'),
        privacyUrl: Uri.parse('https://example.test/privacidade'),
        termsVersion: '2026-09',
        privacyVersion: '2026-08',
      ),
      termsAccepted: true,
      privacyAccepted: true,
    );
    final repository = _repository((incoming) async {
      captured = incoming;
      return http.Response('{}', 201);
    });

    await repository.registerClient(legalRequest);

    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(sent['termsAccepted'], isTrue);
    expect(sent['privacyAccepted'], isTrue);
    expect(sent['termsVersion'], '2026-09');
    expect(sent['privacyVersion'], '2026-08');
    expect(sent, isNot(contains('empresaId')));
    expect(sent, isNot(contains('condominioId')));
    expect(sent, isNot(contains('role')));
  });

  for (final entry in const {
    'CPF_ALREADY_REGISTERED': RegistrationFailureKind.cpfAlreadyRegistered,
    'EMAIL_ALREADY_REGISTERED': RegistrationFailureKind.emailAlreadyRegistered,
  }.entries) {
    test('${entry.key} é mapeado de forma estruturada', () async {
      final repository = _repository(
        (_) async => http.Response(
          jsonEncode({'code': entry.key, 'message': 'detalhe backend'}),
          409,
        ),
      );
      await expectLater(
        repository.registerClient(request),
        throwsA(
          isA<RegistrationException>()
              .having((error) => error.kind, 'kind', entry.value)
              .having((error) => error.code, 'code', entry.key),
        ),
      );
    });
  }

  test('validation preserva fieldErrors sem expor erro técnico', () async {
    final repository = _repository(
      (_) async => http.Response(
        jsonEncode({
          'code': 'INVALID_REGISTRATION_DATA',
          'fieldErrors': {'email': 'E-mail inválido'},
        }),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await expectLater(
      repository.registerClient(request),
      throwsA(
        isA<RegistrationException>()
            .having(
              (error) => error.kind,
              'kind',
              RegistrationFailureKind.validation,
            )
            .having(
              (error) => error.fieldErrors['email'],
              'field error',
              'E-mail inválido',
            ),
      ),
    );
  });

  test('500 vira falha genérica de servidor', () async {
    final repository = _repository((_) async => http.Response('{}', 500));
    await expectLater(
      repository.registerClient(request),
      throwsA(
        isA<RegistrationException>().having(
          (error) => error.kind,
          'kind',
          RegistrationFailureKind.server,
        ),
      ),
    );
  });

  test('ClientException vira falha de conexão', () async {
    final repository = _repository(
      (_) async => throw http.ClientException('offline'),
    );
    await expectLater(
      repository.registerClient(request),
      throwsA(
        isA<RegistrationException>().having(
          (error) => error.code,
          'code',
          'NETWORK_UNAVAILABLE',
        ),
      ),
    );
  });

  test('timeout vira falha recuperável', () async {
    final repository = ClientApiRepository(
      config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
      requestTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      repository.registerClient(request),
      throwsA(
        isA<RegistrationException>().having(
          (error) => error.code,
          'code',
          'REQUEST_TIMEOUT',
        ),
      ),
    );
  });
}

ClientApiRepository _repository(
  Future<http.Response> Function(http.Request) handler,
) => ClientApiRepository(
  config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
  client: MockClient(handler),
);
