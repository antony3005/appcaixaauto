import 'package:appcaixaauto/src/core/theme/app_theme.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/features/auth/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cadastro render 390x844', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: RegistrationPage(repository: _VisualRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RegistrationPage),
      matchesGoldenFile('goldens/registration-390x844.png'),
    );
  });
}

class _VisualRepository implements ClientRepository {
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
      const RegistrationLegalConfig.none();

  @override
  Future<AuthSession> linkTenant(
    AuthSession session,
    String invitationToken,
  ) async => _unavailable();
  Never _unavailable() =>
      throw const AppException('Método fora do escopo desta fixture.');

  @override
  Future<void> registerClient(ClientRegistrationRequest request) async =>
      _unavailable();

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
