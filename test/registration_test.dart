import 'dart:async';

import 'package:appcaixaauto/src/core/theme/app_theme.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/features/auth/login_page.dart';
import 'package:appcaixaauto/src/features/auth/registration_page.dart';
import 'package:appcaixaauto/src/state/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre cadastro a partir do login', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpLogin(tester, repository);

    expect(find.text('Ainda não tem uma conta?'), findsOneWidget);
    final action = find.byKey(const ValueKey('open-registration'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('CRIAR MINHA CONTA'), findsOneWidget);
  });

  testWidgets('form vazio mostra erros inline e não envia', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpRegistration(tester, repository);

    await _tapSubmit(tester);

    expect(find.text('Informe seu nome completo.'), findsOneWidget);
    expect(find.text('CPF inválido.'), findsOneWidget);
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(
      find.text('A senha deve ter no mínimo 6 caracteres.'),
      findsOneWidget,
    );
    expect(find.text('Confirme sua senha.'), findsOneWidget);
    expect(repository.registrationCalls, 0);
  });

  testWidgets('CPF inválido bloqueia request', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpRegistration(tester, repository);

    await tester.enterText(
      find.byKey(const ValueKey('registration-cpf')),
      '11111111111',
    );
    await _tapSubmit(tester);

    expect(find.text('CPF inválido.'), findsOneWidget);
    expect(repository.registrationCalls, 0);
  });

  testWidgets('CPF válido passa pela validação local', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpRegistration(tester, repository);

    await tester.enterText(
      find.byKey(const ValueKey('registration-cpf')),
      '52998224725',
    );
    await _tapSubmit(tester);

    expect(find.text('CPF inválido.'), findsNothing);
    expect(repository.registrationCalls, 0);
  });

  testWidgets('e-mail inválido mostra erro inline', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpRegistration(tester, repository);

    await tester.enterText(
      find.byKey(const ValueKey('registration-email')),
      'cliente-invalido',
    );
    await _tapSubmit(tester);

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(repository.registrationCalls, 0);
  });

  testWidgets('senha menor que contrato do backend é inválida', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpRegistration(tester, repository);

    await tester.enterText(
      find.byKey(const ValueKey('registration-password')),
      '12345',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-confirm-password')),
      '12345',
    );
    await _tapSubmit(tester);

    expect(
      find.text('A senha deve ter no mínimo 6 caracteres.'),
      findsOneWidget,
    );
    expect(repository.registrationCalls, 0);
  });

  testWidgets('senhas diferentes mostram erro inline', (tester) async {
    final repository = _RegistrationRepository();
    await _pumpRegistration(tester, repository);

    await tester.enterText(
      find.byKey(const ValueKey('registration-password')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-confirm-password')),
      '654321',
    );
    await _tapSubmit(tester);

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(repository.registrationCalls, 0);
  });

  testWidgets('loading bloqueia duplo clique e informa progresso', (
    tester,
  ) async {
    final pending = Completer<void>();
    final repository = _RegistrationRepository(pending: pending);
    await _pumpRegistration(tester, repository);
    await _fillValidForm(tester);

    final submit = find.byKey(const ValueKey('registration-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Criando conta...'), findsOneWidget);
    expect(repository.registrationCalls, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('registration-success')), findsOneWidget);
  });

  testWidgets('erro de servidor vira mensagem amigável', (tester) async {
    final repository = _RegistrationRepository(
      failure: const RegistrationException(
        kind: RegistrationFailureKind.server,
        code: 'REGISTRATION_SERVER_ERROR',
        message:
            'Não foi possível criar sua conta agora. Tente novamente mais tarde.',
      ),
    );
    await _pumpRegistration(tester, repository);
    await _fillValidForm(tester);

    await _tapSubmit(tester);

    expect(
      find.text(
        'Não foi possível criar sua conta agora. Tente novamente mais tarde.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('HTTP'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('CPF já cadastrado oferece retorno ao login', (tester) async {
    final repository = _RegistrationRepository(
      failure: const RegistrationException(
        kind: RegistrationFailureKind.cpfAlreadyRegistered,
        code: 'CPF_ALREADY_REGISTERED',
        message: 'Já existe uma conta cadastrada com este CPF.',
      ),
    );
    await _pumpRegistrationFromLogin(tester, repository);
    await _fillValidForm(tester);

    await _tapSubmit(tester);

    expect(
      find.text('Já existe uma conta cadastrada com este CPF.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('duplicate-cpf-login')), findsOneWidget);
    expect(repository.registrationCalls, 1);
  });

  testWidgets('e-mail duplicado aparece no campo sem erro técnico', (
    tester,
  ) async {
    final repository = _RegistrationRepository(
      failure: const RegistrationException(
        kind: RegistrationFailureKind.emailAlreadyRegistered,
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'Este e-mail já está cadastrado.',
        fieldErrors: {'email': 'Este e-mail já está cadastrado.'},
      ),
    );
    await _pumpRegistration(tester, repository);
    await _fillValidForm(tester);

    await _tapSubmit(tester);

    expect(find.text('Este e-mail já está cadastrado.'), findsWidgets);
    expect(find.textContaining('409'), findsNothing);
  });

  testWidgets('falha de rede mantém formulário preenchido para retry', (
    tester,
  ) async {
    final repository = _RegistrationRepository(
      failure: const RegistrationException(
        kind: RegistrationFailureKind.network,
        code: 'NETWORK_UNAVAILABLE',
        message:
            'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
      ),
    );
    await _pumpRegistration(tester, repository);
    await _fillValidForm(tester);

    await _tapSubmit(tester);

    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('registration-name')),
    );
    expect(nameField.controller?.text, '  Maria   da Silva  ');
    expect(find.text('CRIAR MINHA CONTA'), findsOneWidget);
  });

  testWidgets('sucesso confirma e volta para Login sem JWT local', (
    tester,
  ) async {
    final repository = _RegistrationRepository();
    await _pumpRegistrationFromLogin(tester, repository);
    await _fillValidForm(tester);

    await _tapSubmit(tester);

    expect(find.text('Cadastro concluído'), findsOneWidget);
    expect(repository.lastRequest?.firstName, 'Maria');
    expect(repository.lastRequest?.lastName, 'da Silva');
    expect(repository.lastRequest?.cpf, '52998224725');
    expect(repository.lastRequest?.phone, '75999999999');

    await tester.tap(find.byKey(const ValueKey('success-login')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Seu condomínio'), findsOneWidget);
    expect(find.text('Cadastro concluído'), findsNothing);
  });

  testWidgets('documentos configurados bloqueiam envio até os dois aceites', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _RegistrationRepository(
      legalConfig: RegistrationLegalConfig(
        termsUrl: Uri.parse('https://example.test/termos'),
        privacyUrl: Uri.parse('https://example.test/privacidade'),
        termsVersion: '2026-09',
        privacyVersion: '2026-08',
      ),
    );
    await _pumpRegistration(tester, repository);
    await _fillValidForm(tester);

    final submit = find.byKey(const ValueKey('registration-submit'));
    await tester.ensureVisible(submit);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);

    final terms = find.byKey(const ValueKey('accept-terms'));
    final privacy = find.byKey(const ValueKey('accept-privacy'));
    final termsCheckbox = find.descendant(
      of: terms,
      matching: find.byType(Checkbox),
    );
    final privacyCheckbox = find.descendant(
      of: privacy,
      matching: find.byType(Checkbox),
    );
    await tester.ensureVisible(termsCheckbox);
    await tester.tap(termsCheckbox);
    await tester.pump();
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);

    await tester.ensureVisible(privacyCheckbox);
    await tester.tap(privacyCheckbox);
    await tester.pump();
    await tester.ensureVisible(submit);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.registrationCalls, 1);
    expect(repository.lastRequest?.termsAccepted, isTrue);
    expect(repository.lastRequest?.privacyAccepted, isTrue);
    expect(repository.lastRequest?.termsVersion, '2026-09');
    expect(repository.lastRequest?.privacyVersion, '2026-08');
  });

  testWidgets('carregamento legal concluído após dispose não atualiza a tela', (
    tester,
  ) async {
    final pending = Completer<RegistrationLegalConfig>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: RegistrationPage(
          repository: _RegistrationRepository(legalConfigPending: pending),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('legal-config-loading')), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    pending.complete(const RegistrationLegalConfig.none());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('aceites legais suportam tela pequena e texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _RegistrationRepository(
      legalConfig: RegistrationLegalConfig(
        termsUrl: Uri.parse('https://example.test/termos'),
        privacyUrl: Uri.parse('https://example.test/privacidade'),
        termsVersion: '2026-09',
        privacyVersion: '2026-08',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: RegistrationPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final acceptance = find.byKey(const ValueKey('legal-acceptance'));
    await tester.scrollUntilVisible(
      acceptance,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(acceptance, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets(
      'sem overflow com teclado aberto em ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
              child: child!,
            ),
            home: RegistrationPage(repository: _RegistrationRepository()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final submit = find.byKey(const ValueKey('registration-submit'));
        await tester.scrollUntilVisible(
          submit,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpLogin(
  WidgetTester tester,
  ClientRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: LoginPage(controller: ClientController(repository)),
    ),
  );
}

Future<void> _pumpRegistration(
  WidgetTester tester,
  ClientRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: RegistrationPage(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpRegistrationFromLogin(
  WidgetTester tester,
  ClientRepository repository,
) async {
  await _pumpLogin(tester, repository);
  final action = find.byKey(const ValueKey('open-registration'));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('registration-name')),
    '  Maria   da Silva  ',
  );
  await tester.enterText(
    find.byKey(const ValueKey('registration-cpf')),
    '52998224725',
  );
  await tester.enterText(
    find.byKey(const ValueKey('registration-email')),
    'maria@email.com',
  );
  await tester.enterText(
    find.byKey(const ValueKey('registration-phone')),
    '75999999999',
  );
  await tester.enterText(
    find.byKey(const ValueKey('registration-password')),
    'segredo',
  );
  await tester.enterText(
    find.byKey(const ValueKey('registration-confirm-password')),
    'segredo',
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.byKey(const ValueKey('registration-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

class _RegistrationRepository implements ClientRepository {
  _RegistrationRepository({
    this.pending,
    this.failure,
    this.legalConfig = const RegistrationLegalConfig.none(),
    this.legalConfigPending,
  });

  final Completer<void>? pending;
  final RegistrationException? failure;
  final RegistrationLegalConfig legalConfig;
  final Completer<RegistrationLegalConfig>? legalConfigPending;
  int registrationCalls = 0;
  ClientRegistrationRequest? lastRequest;

  @override
  Future<void> requestPasswordRecovery(String cpf) async => _unavailable();

  @override
  Future<String> validatePasswordRecoveryCode(String cpf, String code) async =>
      _unavailable();

  @override
  Future<void> resetPassword({
    required String cpf,
    required String resetToken,
    required String newPassword,
  }) async => _unavailable();

  @override
  Future<RegistrationLegalConfig> loadRegistrationLegalConfig() async =>
      legalConfigPending == null ? legalConfig : legalConfigPending!.future;

  @override
  Future<AuthSession> linkTenant(
    AuthSession session,
    String invitationToken,
  ) async => _unavailable();

  @override
  Future<void> registerClient(ClientRegistrationRequest request) async {
    registrationCalls++;
    lastRequest = request;
    if (failure != null) throw failure!;
    if (pending != null) await pending!.future;
  }

  Never _unavailable() =>
      throw const AppException('Método fora do escopo desta fixture.');

  @override
  Future<AuthSession> login({
    required String cpf,
    required String password,
  }) async => _unavailable();

  @override
  Future<ClientBootstrap> loadBootstrap(AuthSession session) async =>
      _unavailable();

  @override
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session) async =>
      _unavailable();

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) async => _unavailable();

  @override
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  ) async => _unavailable();

  @override
  Future<ClientBootstrap> redeemReward(
    AuthSession session,
    String rewardId,
  ) async => _unavailable();
}
