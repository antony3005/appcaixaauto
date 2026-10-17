import 'package:appcaixaauto/src/core/theme/app_theme.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/features/home/home_page.dart';
import 'package:appcaixaauto/src/state/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures = <(String, Size, double)>[
    ('360x800', const Size(360, 800), 1),
    ('390x844-text-130', const Size(390, 844), 1.3),
    ('430x932', const Size(430, 932), 1),
  ];

  for (final fixture in fixtures) {
    testWidgets('home render ${fixture.$1}', (tester) async {
      tester.view.physicalSize = fixture.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ClientController(_VisualRepository())
        ..session = const AuthSession(token: 'visual-test', user: _user)
        ..data = _data
        ..phase = LoadPhase.ready;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(fixture.$3)),
            child: HomePage(controller: controller, data: _data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(HomePage),
        matchesGoldenFile('goldens/home-${fixture.$1}.png'),
      );
    });
  }
}

const _user = ClientUser(
  id: 'user-visual',
  firstName: 'Jefferson',
  lastName: 'Silva',
  email: 'cliente@example.com',
  cpf: '12345678901',
  phone: '5575999999999',
);

final _data = ClientBootstrap(
  user: _user,
  condominium: const CondominiumSummary(
    id: 'cond-visual',
    name: 'Residencial Parque das Flores',
  ),
  capabilities: const ClientCapabilities(
    catalog: true,
    promotions: true,
    loyalty: true,
    points: true,
    coupons: true,
  ),
  products: const [
    ProductSummary(
      id: 'p1',
      name: 'Café torrado e moído tradicional 500 g',
      category: 'Mercearia',
      unit: 'Pacote 500 g',
      price: 18.9,
      originalPrice: 22.5,
    ),
    ProductSummary(
      id: 'p2',
      name: 'Água mineral sem gás',
      category: 'Bebidas',
      unit: 'Garrafa 1,5 L',
      price: 4.5,
    ),
  ],
  purchases: [
    PurchaseSummary(
      id: 'order-visual',
      status: PurchaseStatus.approved,
      subtotal: 25.4,
      discount: 1.93,
      total: 23.47,
      createdAt: DateTime(2026, 9, 13, 18, 42),
      condominiumName: 'Residencial Parque das Flores',
      itemCount: 3,
    ),
  ],
  loyalty: const LoyaltySummary(
    points: 850,
    nextRewardPoints: 1000,
    couponsAvailable: 1,
  ),
);

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
