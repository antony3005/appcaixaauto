import 'dart:async';

import 'package:appcaixaauto/src/core/theme/app_theme.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/features/qr/customer_identification_page.dart';
import 'package:appcaixaauto/src/state/customer_identification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  late DateTime now;

  setUp(() => now = DateTime.parse('2026-09-30T13:00:00Z'));

  testWidgets('exibe loading e bloqueia botão enquanto gera', (tester) async {
    final pending = Completer<CustomerIdentificationToken>();
    final fixture = _fixture(() => pending.future, () => now);

    await _pump(tester, fixture.controller);

    expect(find.text('Gerando seu QR...'), findsWidgets);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('customer-qr-generate')),
    );
    expect(button.onPressed, isNull);
    pending.complete(_token('loading-complete', now));
    await tester.pump();
    await _disposePage(tester);
  });

  testWidgets('renderiza exatamente o qrPayload do backend sem PII', (
    tester,
  ) async {
    const payload = 'app247://customer-link/opaque-from-backend';
    final fixture = _fixture(
      () async => _token('opaque-from-backend', now),
      () => now,
    );

    await _pump(tester, fixture.controller);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('customer-identification-qr')),
      findsOneWidget,
    );
    expect(fixture.controller.token?.qrPayload, payload);
    expect(payload, isNot(contains(_session.user.cpf)));
    expect(payload, isNot(contains(_session.user.id)));
    expect(payload, isNot(contains(_session.token)));
    expect(find.text('Expira em 02:00'), findsOneWidget);
    await _disposePage(tester);
  });

  testWidgets('ao voltar do background remove QR expirado', (tester) async {
    final fixture = _fixture(
      () async => _token('qr-a', now, ttl: 2),
      () => now,
    );
    await _pump(tester, fixture.controller);
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);

    now = now.add(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('QR expirado'), findsOneWidget);
    expect(find.text('GERAR NOVO QR'), findsOneWidget);
  });

  testWidgets('erro permite retry e troca QR A por QR B', (tester) async {
    var call = 0;
    final fixture = _fixture(() async {
      call++;
      if (call == 1) throw const AppException('Falha amigável.');
      return _token('qr-b', now);
    }, () => now);

    await _pump(tester, fixture.controller);
    await tester.pump();
    expect(find.text('Falha amigável.'), findsOneWidget);
    expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);

    await tester.ensureVisible(find.text('TENTAR NOVAMENTE'));
    await tester.tap(find.text('TENTAR NOVAMENTE'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(fixture.controller.token?.qrPayload, endsWith('qr-b'));
    await _disposePage(tester);
  });

  testWidgets('offline tem mensagem específica', (tester) async {
    final fixture = _fixture(
      () async => throw const NetworkUnavailableException(),
      () => now,
    );

    await _pump(tester, fixture.controller);
    await tester.pump();

    expect(find.textContaining('Você está offline'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  for (final size in const [Size(320, 568), Size(430, 932), Size(800, 1280)]) {
    testWidgets(
      'não tem overflow em ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final fixture = _fixture(
          () async => _token('responsive', now),
          () => now,
        );

        await _pump(tester, fixture.controller);
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(QrImageView), findsOneWidget);
        await _disposePage(tester);
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  CustomerIdentificationController controller,
) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: CustomerIdentificationPage(
      repository: controller.repository,
      session: _session,
      loyaltyMode: LoyaltyMode.points,
      controller: controller,
    ),
  ),
);

Future<void> _disposePage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

({CustomerIdentificationController controller, _QrRepository repository})
_fixture(
  Future<CustomerIdentificationToken> Function() loader,
  DateTime Function() now,
) {
  final repository = _QrRepository(loader);
  return (
    controller: CustomerIdentificationController(
      repository: repository,
      session: _session,
      now: now,
    ),
    repository: repository,
  );
}

const _session = AuthSession(
  token: 'jwt-never-in-qr',
  user: ClientUser(
    id: 'user-never-in-qr',
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@example.test',
    cpf: '52998224725',
    phone: '71999999999',
  ),
);

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

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) => loader();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
