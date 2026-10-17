import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const session = AuthSession(
    token: 'jwt-only-in-authorization-header',
    user: ClientUser(
      id: 'user-a',
      firstName: 'Ana',
      lastName: 'Silva',
      email: 'ana@example.test',
      cpf: '52998224725',
      phone: '71999999999',
    ),
  );

  test(
    'POST usa JWT existente, body vazio e preserva qrPayload recebido',
    () async {
      late http.Request captured;
      final repository = _repository(
        MockClient((request) async {
          captured = request;
          return http.Response(
            '{"qrPayload":"app247://customer-link/opaque-from-backend",'
            '"expiresAt":"2026-09-30T13:02:00Z",'
            '"serverTime":"2026-09-30T13:00:00Z"}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await repository.createIdentificationToken(session);

      expect(captured.method, 'POST');
      expect(captured.url.path, '/app-cliente/identificacao-tokens');
      expect(captured.headers['Authorization'], 'Bearer ${session.token}');
      expect(captured.body, isEmpty);
      expect(result.qrPayload, 'app247://customer-link/opaque-from-backend');
      expect(result.qrPayload, isNot(contains(session.user.cpf)));
      expect(result.qrPayload, isNot(contains(session.user.id)));
      expect(result.qrPayload, isNot(contains(session.token)));
    },
  );

  for (final fixture in <(int, String?, String)>[
    (401, 'AUTH_REQUIRED', 'Sua sessão expirou'),
    (403, 'TENANT_MISMATCH', 'não tem permissão'),
    (400, 'INVALID_REQUEST', 'Não foi possível gerar'),
    (500, null, 'indisponível'),
  ]) {
    test('mapeia HTTP ${fixture.$1} sem expor resposta técnica', () async {
      final code = fixture.$2 == null ? 'null' : '"${fixture.$2}"';
      final repository = _repository(
        MockClient(
          (_) async => http.Response(
            '{"code":$code,"message":"technical detail"}',
            fixture.$1,
          ),
        ),
      );

      await expectLater(
        repository.createIdentificationToken(session),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'message',
            contains(fixture.$3),
          ),
        ),
      );
    });
  }

  test('mapeia conta sem condomínio pelo código real', () async {
    final repository = _repository(
      MockClient(
        (_) async => http.Response(
          '{"code":"CONDOMINIUM_REQUIRED","message":"technical"}',
          409,
        ),
      ),
    );

    await expectLater(
      repository.createIdentificationToken(session),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Sua conta ainda não está vinculada a um condomínio.',
        ),
      ),
    );
  });

  test('mapeia timeout', () async {
    final repository = _repository(
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 201);
      }),
      timeout: const Duration(milliseconds: 1),
    );

    await expectLater(
      repository.createIdentificationToken(session),
      throwsA(isA<RequestTimeoutException>()),
    );
  });

  test('mapeia ausência de conexão', () async {
    final repository = _repository(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      repository.createIdentificationToken(session),
      throwsA(isA<NetworkUnavailableException>()),
    );
  });
}

ClientApiRepository _repository(
  http.Client client, {
  Duration timeout = const Duration(seconds: 1),
}) => ClientApiRepository(
  config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
  client: client,
  requestTimeout: timeout,
);
