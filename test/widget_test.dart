import 'package:appcaixaauto/src/app.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login exige CPF e senha sem expor checkout', (tester) async {
    await tester.pumpWidget(App247Client(repository: FixtureRepository()));

    expect(find.textContaining('Seu condomínio'), findsOneWidget);
    expect(find.textContaining('Finalizar compra'), findsNothing);
    expect(find.text('Carrinho'), findsNothing);

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe um CPF com 11 números.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('home prioriza ofertas, catálogo, fidelidade e compras', (
    tester,
  ) async {
    await tester.pumpWidget(App247Client(repository: FixtureRepository()));
    await tester.enterText(find.byType(TextFormField).at(0), '123.456.789-01');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo8');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Jefferson'), findsOneWidget);
    expect(find.text('Residencial Parque das Flores'), findsWidgets);
    expect(find.text('Catálogo'), findsWidgets);
    expect(find.text('850 pts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ofertas para você'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ofertas para você'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Compras recentes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Compras recentes'), findsOneWidget);
    expect(find.text('Aprovada'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Benefícios'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Comprar'), findsNothing);
    expect(find.text('Adicionar ao carrinho'), findsNothing);
  });

  testWidgets('home vazia remove seções opcionais desativadas', (tester) async {
    await tester.pumpWidget(
      App247Client(repository: FixtureRepository(empty: true)),
    );
    await tester.enterText(find.byType(TextFormField).at(0), '123.456.789-01');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo8');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Seu histórico começa aqui'), findsOneWidget);
    expect(find.text('Benefícios'), findsNothing);
    expect(find.text('Ofertas para você'), findsNothing);
    expect(find.text('Catálogo'), findsNothing);
  });

  testWidgets('atalho Meu QR abre identificação sem fluxo de pagamento', (
    tester,
  ) async {
    await tester.pumpWidget(App247Client(repository: FixtureRepository()));
    await tester.enterText(find.byType(TextFormField).at(0), '123.456.789-01');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo8');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Meu QR'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('open-customer-identification')),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Meu QR'), findsWidgets);
    expect(find.text('IDENTIFICAÇÃO APP247'), findsOneWidget);
    expect(find.textContaining('Pagar no app'), findsNothing);
    expect(find.textContaining('Finalizar compra'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}

class FixtureRepository implements ClientRepository {
  @override
  Future<void> requestPasswordRecovery(String cpf) async {}

  @override
  Future<String> validatePasswordRecoveryCode(String cpf, String code) async =>
      'fixture-reset-token';

  @override
  Future<void> resetPassword({
    required String cpf,
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<RegistrationLegalConfig> loadRegistrationLegalConfig() async =>
      const RegistrationLegalConfig.none();

  @override
  Future<AuthSession> linkTenant(
    AuthSession session,
    String invitationToken,
  ) async => throw const AppException('Método fora do escopo desta fixture.');
  FixtureRepository({this.empty = false});
  final bool empty;

  static const user = ClientUser(
    id: 'user-fixture',
    firstName: 'Jefferson',
    lastName: 'Silva',
    email: 'jefferson@example.com',
    cpf: '12345678901',
    phone: '5575999999999',
  );

  @override
  Future<void> registerClient(ClientRegistrationRequest request) async {}

  @override
  Future<AuthSession> login({
    required String cpf,
    required String password,
  }) async => const AuthSession(token: 'test-token-not-production', user: user);

  @override
  Future<ClientBootstrap> loadBootstrap(AuthSession session) async {
    if (empty) {
      return const ClientBootstrap(
        user: user,
        capabilities: ClientCapabilities(),
        purchases: [],
      );
    }
    return ClientBootstrap(
      user: user,
      condominium: const CondominiumSummary(
        id: 'cond-fixture',
        name: 'Residencial Parque das Flores',
      ),
      capabilities: const ClientCapabilities(
        catalog: true,
        promotions: true,
        loyalty: true,
        points: true,
        rewards: true,
        coupons: true,
        identificationQr: true,
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
          id: 'order-fixture',
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
        mode: LoyaltyMode.points,
        points: 850,
        nextRewardPoints: 1000,
        couponsAvailable: 1,
      ),
      rewards: const [
        RewardSummary(
          id: 'reward-fixture',
          title: '10% OFF',
          pointsCost: 500,
          minimumPurchase: 100,
          maximumDiscount: 25,
        ),
      ],
      coupons: [
        CouponSummary(
          id: 'coupon-fixture',
          title: '10% OFF',
          minimumPurchase: 100,
          maximumDiscount: 25,
          validUntil: DateTime(2026, 10, 30),
          status: CouponStatus.available,
        ),
      ],
    );
  }

  @override
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session) async =>
      (await loadBootstrap(session)).purchases;

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) async => CustomerIdentificationToken(
    qrPayload: 'app247://customer-link/opaque-test-token',
    expiresAt: DateTime.now().add(const Duration(seconds: 90)),
    serverTime: DateTime.now(),
  );

  @override
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  ) async => TemporaryQrToken(
    value: 'opaque-test-coupon-token',
    expiresAt: DateTime.now().add(const Duration(seconds: 90)),
  );

  @override
  Future<ClientBootstrap> redeemReward(AuthSession session, String rewardId) =>
      loadBootstrap(session);
}
