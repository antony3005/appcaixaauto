import 'dart:async';

import 'package:appcaixaauto/src/core/theme/app_theme.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/features/shell/client_shell.dart';
import 'package:appcaixaauto/src/state/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login global mostra estado explícito sem seletor de tenant', (
    tester,
  ) async {
    final repository = _GlobalAccountRepository();
    final controller = ClientController(repository);

    expect(
      await controller.login(cpf: '52998224725', password: 'segredo'),
      isTrue,
    );
    expect(controller.phase, LoadPhase.tenantLinkRequired);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ClientShell(controller: controller),
      ),
    );

    expect(find.text('Vincular condomínio'), findsOneWidget);
    expect(find.text('Vincule seu condomínio'), findsOneWidget);
    expect(find.textContaining('convite'), findsWidgets);
    expect(find.textContaining('Escolha sua empresa'), findsNothing);
    expect(find.textContaining('Escolha seu condomínio'), findsNothing);
    expect(find.text('JÁ FUI VINCULADO, ATUALIZAR'), findsOneWidget);
  });

  testWidgets('estado sem tenant não transborda em tela pequena e texto 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ClientController(_GlobalAccountRepository());
    await controller.login(cpf: '52998224725', password: 'segredo');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: ClientShell(controller: controller),
      ),
    );

    expect(tester.takeException(), isNull);
    final action = find.text('JÁ FUI VINCULADO, ATUALIZAR');
    await tester.scrollUntilVisible(
      action,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(action, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'convite válido troca sessão, carrega tenant e bloqueia duplo envio',
    (tester) async {
      final pending = Completer<void>();
      final repository = _GlobalAccountRepository(linkPending: pending);
      final controller = ClientController(repository);
      await controller.login(cpf: '52998224725', password: 'segredo');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ClientShell(controller: controller),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tenant-invitation-token')),
        'opaque-invitation',
      );
      final submit = find.byKey(const ValueKey('tenant-link-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.tap(submit);
      await tester.pump();

      expect(repository.linkCalls, 1);
      expect(repository.lastInvitation, 'opaque-invitation');
      expect(find.text('VINCULANDO...'), findsOneWidget);

      pending.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.phase, LoadPhase.ready);
      expect(controller.session?.token, 'jwt-linked');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ClientShell(controller: controller),
        ),
      );
      expect(find.text('Conta criada'), findsNothing);
    },
  );

  testWidgets('convite inválido mantém tela e mostra mensagem amigável', (
    tester,
  ) async {
    final repository = _GlobalAccountRepository(
      linkFailure: const AppException(
        'Este convite é inválido, expirou ou não pertence à sua conta.',
        code: 'TENANT_INVITATION_INVALID',
        statusCode: 404,
      ),
    );
    final controller = ClientController(repository);
    await controller.login(cpf: '52998224725', password: 'segredo');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ClientShell(controller: controller),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('tenant-invitation-token')),
      'invalid',
    );
    final submit = find.byKey(const ValueKey('tenant-link-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(controller.phase, LoadPhase.tenantLinkRequired);
    expect(find.byKey(const ValueKey('tenant-link-error')), findsOneWidget);
    expect(find.textContaining('não pertence à sua conta'), findsOneWidget);
    expect(find.textContaining('404'), findsNothing);
  });
}

class _GlobalAccountRepository implements ClientRepository {
  _GlobalAccountRepository({this.linkPending, this.linkFailure});

  final Completer<void>? linkPending;
  final AppException? linkFailure;
  int linkCalls = 0;
  String? lastInvitation;

  static const user = ClientUser(
    id: 'user-global',
    firstName: 'Maria',
    lastName: 'Silva',
    email: 'maria@example.com',
    cpf: '52998224725',
    phone: '',
  );

  @override
  Future<void> requestPasswordRecovery(String cpf) async => _unused();

  @override
  Future<String> validatePasswordRecoveryCode(String cpf, String code) async =>
      _unused();

  @override
  Future<void> resetPassword({
    required String cpf,
    required String resetToken,
    required String newPassword,
  }) async => _unused();

  @override
  Future<RegistrationLegalConfig> loadRegistrationLegalConfig() async =>
      const RegistrationLegalConfig.none();

  @override
  Future<AuthSession> linkTenant(
    AuthSession session,
    String invitationToken,
  ) async {
    linkCalls++;
    lastInvitation = invitationToken;
    if (linkFailure != null) throw linkFailure!;
    if (linkPending != null) await linkPending!.future;
    return const AuthSession(token: 'jwt-linked', user: user);
  }

  @override
  Future<AuthSession> login({
    required String cpf,
    required String password,
  }) async => const AuthSession(token: 'jwt-global', user: user);

  @override
  Future<ClientBootstrap> loadBootstrap(AuthSession session) async {
    if (session.token == 'jwt-linked') {
      return const ClientBootstrap(
        user: user,
        capabilities: ClientCapabilities(),
        purchases: [],
        condominium: CondominiumSummary(id: 'condo-a', name: 'Residencial A'),
      );
    }
    throw const AppException(
      'Sua conta ainda não está vinculada a um condomínio.',
      code: 'TENANT_LINK_REQUIRED',
      statusCode: 409,
    );
  }

  Never _unused() =>
      throw const AppException('Método fora do escopo desta fixture.');

  @override
  Future<void> registerClient(ClientRegistrationRequest request) async =>
      _unused();

  @override
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session) async =>
      _unused();

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) async => _unused();

  @override
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  ) async => _unused();

  @override
  Future<ClientBootstrap> redeemReward(
    AuthSession session,
    String rewardId,
  ) async => _unused();
}
