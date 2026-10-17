import 'dart:async';

import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/state/customer_identification_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = AuthSession(
    token: 'jwt-session',
    user: ClientUser(
      id: 'user-a',
      firstName: 'Ana',
      lastName: 'Silva',
      email: 'ana@example.test',
      cpf: '52998224725',
      phone: '71999999999',
    ),
  );
  late DateTime now;

  setUp(() => now = DateTime.parse('2026-09-30T13:00:00Z'));

  test('vai de loading para valid e bloqueia geração simultânea', () async {
    final pending = Completer<CustomerIdentificationToken>();
    final repository = _QrRepository(() => pending.future);
    final controller = CustomerIdentificationController(
      repository: repository,
      session: session,
      now: () => now,
    );
    addTearDown(controller.dispose);

    final first = controller.generate();
    final second = controller.generate();
    expect(controller.phase, CustomerIdentificationPhase.loading);
    expect(repository.calls, 1);
    pending.complete(_token('qr-a', now));
    await Future.wait([first, second]);

    expect(controller.phase, CustomerIdentificationPhase.valid);
    expect(controller.token?.qrPayload, 'app247://customer-link/qr-a');
  });

  test('remove QR da UI quando expiresAt é atingido', () async {
    final repository = _QrRepository(() async => _token('qr-a', now, ttl: 2));
    final controller = CustomerIdentificationController(
      repository: repository,
      session: session,
      now: () => now,
    );
    addTearDown(controller.dispose);

    await controller.generate();
    expect(controller.phase, CustomerIdentificationPhase.valid);
    now = now.add(const Duration(seconds: 3));
    controller.refreshForCurrentTime();

    expect(controller.phase, CustomerIdentificationPhase.expired);
    expect(controller.token, isNull);
  });

  test('gerar novo substitui QR anterior', () async {
    var index = 0;
    final repository = _QrRepository(
      () async => _token(index++ == 0 ? 'qr-a' : 'qr-b', now),
    );
    final controller = CustomerIdentificationController(
      repository: repository,
      session: session,
      now: () => now,
    );
    addTearDown(controller.dispose);

    await controller.generate();
    expect(controller.token?.qrPayload, endsWith('qr-a'));
    await controller.generate();
    expect(controller.token?.qrPayload, endsWith('qr-b'));
    expect(repository.calls, 2);
  });

  test('offline possui estado e mensagem próprios', () async {
    final controller = CustomerIdentificationController(
      repository: _QrRepository(
        () async => throw const NetworkUnavailableException(),
      ),
      session: session,
      now: () => now,
    );
    addTearDown(controller.dispose);

    await controller.generate();

    expect(controller.phase, CustomerIdentificationPhase.offline);
    expect(controller.errorMessage, contains('offline'));
  });

  test('dispose invalida resposta assíncrona sem notificar depois', () async {
    final pending = Completer<CustomerIdentificationToken>();
    final controller = CustomerIdentificationController(
      repository: _QrRepository(() => pending.future),
      session: session,
      now: () => now,
    );
    final operation = controller.generate();
    controller.dispose();
    pending.complete(_token('qr-a', now));
    await operation;
  });
}

CustomerIdentificationToken _token(
  String value,
  DateTime now, {
  int ttl = 120,
}) => CustomerIdentificationToken(
  qrPayload: 'app247://customer-link/$value',
  expiresAt: now.add(Duration(seconds: ttl)),
  serverTime: now,
);

class _QrRepository implements ClientRepository {
  _QrRepository(this.loader);
  final Future<CustomerIdentificationToken> Function() loader;
  int calls = 0;

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) {
    calls++;
    return loader();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
