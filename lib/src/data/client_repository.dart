import '../domain/models.dart';
import '../domain/client_registration.dart';

typedef SessionExpiredHandler = Future<void> Function();

abstract interface class ClientRepository {
  Future<AuthSession> login({required String cpf, required String password});
  Future<void> requestPasswordRecovery(String cpf);
  Future<String> validatePasswordRecoveryCode(String cpf, String code);
  Future<void> resetPassword({
    required String cpf,
    required String resetToken,
    required String newPassword,
  });
  Future<RegistrationLegalConfig> loadRegistrationLegalConfig();
  Future<void> registerClient(ClientRegistrationRequest request);
  Future<AuthSession> linkTenant(AuthSession session, String invitationToken);
  Future<ClientBootstrap> loadBootstrap(AuthSession session);
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session);
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  );
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  );
  Future<ClientBootstrap> redeemReward(AuthSession session, String rewardId);
}

abstract interface class SessionExpirationAware {
  void setSessionExpiredHandler(SessionExpiredHandler handler);
}

abstract interface class ClientFeatureRepository {
  Future<PageResult<ProductSummary>> loadCatalog(
    AuthSession session, {
    String? query,
    String? category,
    int page = 0,
    int size = 20,
  });
  Future<PageResult<PurchaseSummary>> loadPurchasePage(
    AuthSession session, {
    int page = 0,
    int size = 20,
  });
  Future<PurchaseDetail> loadPurchase(AuthSession session, String purchaseId);
  Future<ReceiptImage> loadReceipt(AuthSession session, String purchaseId);
  Future<void> sendReceipt(
    AuthSession session,
    String purchaseId, {
    required String channel,
    required String recipient,
  });
  Future<SupportResult> requestPurchaseSupport(
    AuthSession session,
    String purchaseId, {
    required String category,
    required String message,
  });
  Future<LoyaltySummary> loadLoyalty(AuthSession session);
  Future<List<RewardSummary>> loadRewards(AuthSession session);
  Future<RedemptionResult> redeemRewardWithKey(
    AuthSession session,
    String rewardId,
    String idempotencyKey,
  );
  Future<List<CouponSummary>> loadCoupons(AuthSession session);
  Future<PreferenceSettings> loadPreferences(AuthSession session);
  Future<PreferenceSettings> updatePreferences(
    AuthSession session,
    PreferenceSettings preferences,
  );
}
