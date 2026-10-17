import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/data/session_store.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/state/client_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login persiste JWT e nova instância restaura a sessão', () async {
    final store = MemorySessionStore();
    final repository = _SessionRepository();
    final firstRun = ClientController(repository, sessionStore: store);

    expect(
      await firstRun.login(cpf: '52998224725', password: 'segredo8'),
      isTrue,
    );
    expect(store.value?.token, 'persisted-jwt');

    final restarted = ClientController(repository, sessionStore: store);
    await restarted.initialize();

    expect(restarted.initialized, isTrue);
    expect(restarted.session?.token, 'persisted-jwt');
    expect(restarted.phase, LoadPhase.ready);
    expect(repository.bootstrapCalls, 2);
  });

  test('expiração global limpa storage, shell e navegação', () async {
    final store = MemorySessionStore();
    final controller = ClientController(
      _SessionRepository(),
      sessionStore: store,
    );
    await controller.login(cpf: '52998224725', password: 'segredo8');
    controller.selectNavigation(3);

    await controller.expireSession();

    expect(store.value, isNull);
    expect(controller.session, isNull);
    expect(controller.data, isNull);
    expect(controller.phase, LoadPhase.idle);
    expect(controller.navigationIndex, 0);
    expect(controller.errorMessage, contains('sessão expirou'));
  });

  test('sessão serializada preserva apenas os dados necessários', () {
    final restored = AuthSession.fromJson(_SessionRepository.session.toJson());

    expect(restored.token, 'persisted-jwt');
    expect(restored.user.fullName, 'Ana Silva');
    expect(restored.user.cpf, '52998224725');
  });

  test('retry lógico de resgate reutiliza a mesma Idempotency-Key', () async {
    final repository = _RedemptionRepository();
    final controller = ClientController(repository);
    await controller.login(cpf: '52998224725', password: 'segredo8');

    expect(await controller.redeemReward('reward-1'), isFalse);
    expect(await controller.redeemReward('reward-1'), isTrue);

    expect(repository.keys, hasLength(2));
    expect(repository.keys.first, repository.keys.last);
  });
}

class _SessionRepository implements ClientRepository {
  static const user = ClientUser(
    id: 'user-1',
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@example.test',
    cpf: '52998224725',
    phone: '5575999999999',
  );
  static const session = AuthSession(token: 'persisted-jwt', user: user);
  int bootstrapCalls = 0;

  @override
  Future<AuthSession> login({
    required String cpf,
    required String password,
  }) async => session;

  @override
  Future<ClientBootstrap> loadBootstrap(AuthSession session) async {
    bootstrapCalls++;
    return const ClientBootstrap(
      user: user,
      capabilities: ClientCapabilities(),
      purchases: [],
    );
  }

  @override
  Future<void> requestPasswordRecovery(String cpf) async {}

  @override
  Future<String> validatePasswordRecoveryCode(String cpf, String code) async =>
      'reset-token';

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
  Future<void> registerClient(ClientRegistrationRequest request) async {}

  @override
  Future<AuthSession> linkTenant(
    AuthSession session,
    String invitationToken,
  ) async => session;

  @override
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session) async => [];

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) async => CustomerIdentificationToken(
    qrPayload: 'opaque',
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    serverTime: DateTime.now(),
  );

  @override
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  ) async => TemporaryQrToken(
    value: 'opaque',
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    serverTime: DateTime.now(),
  );

  @override
  Future<ClientBootstrap> redeemReward(AuthSession session, String rewardId) =>
      loadBootstrap(session);
}

class _RedemptionRepository extends _SessionRepository
    implements ClientFeatureRepository {
  final keys = <String>[];

  @override
  Future<RedemptionResult> redeemRewardWithKey(
    AuthSession session,
    String rewardId,
    String idempotencyKey,
  ) async {
    keys.add(idempotencyKey);
    if (keys.length == 1) {
      throw const AppException('Falha transitória.');
    }
    return const RedemptionResult(
      id: 'redemption-1',
      couponId: 'coupon-1',
      status: 'COMPLETED',
    );
  }

  @override
  Future<LoyaltySummary> loadLoyalty(AuthSession session) async =>
      const LoyaltySummary(mode: LoyaltyMode.points, points: 500);

  @override
  Future<List<RewardSummary>> loadRewards(AuthSession session) async => [];

  @override
  Future<List<CouponSummary>> loadCoupons(AuthSession session) async => [];

  @override
  Future<PageResult<ProductSummary>> loadCatalog(
    AuthSession session, {
    String? query,
    String? category,
    int page = 0,
    int size = 20,
  }) async => PageResult(
    content: const [],
    page: page,
    size: size,
    totalElements: 0,
    totalPages: 0,
  );

  @override
  Future<PageResult<PurchaseSummary>> loadPurchasePage(
    AuthSession session, {
    int page = 0,
    int size = 20,
  }) async => PageResult(
    content: const [],
    page: page,
    size: size,
    totalElements: 0,
    totalPages: 0,
  );

  @override
  Future<PurchaseDetail> loadPurchase(AuthSession session, String purchaseId) =>
      throw UnimplementedError();

  @override
  Future<ReceiptImage> loadReceipt(AuthSession session, String purchaseId) =>
      throw UnimplementedError();

  @override
  Future<void> sendReceipt(
    AuthSession session,
    String purchaseId, {
    required String channel,
    required String recipient,
  }) => throw UnimplementedError();

  @override
  Future<SupportResult> requestPurchaseSupport(
    AuthSession session,
    String purchaseId, {
    required String category,
    required String message,
  }) => throw UnimplementedError();

  @override
  Future<PreferenceSettings> loadPreferences(AuthSession session) =>
      throw UnimplementedError();

  @override
  Future<PreferenceSettings> updatePreferences(
    AuthSession session,
    PreferenceSettings preferences,
  ) => throw UnimplementedError();
}
