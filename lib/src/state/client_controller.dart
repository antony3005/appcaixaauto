import 'package:flutter/foundation.dart';

import '../data/client_repository.dart';
import '../data/session_store.dart';
import '../domain/models.dart';

class ClientController extends ChangeNotifier {
  ClientController(this.repository, {SessionStore? sessionStore})
    : sessionStore = sessionStore ?? MemorySessionStore() {
    if (repository is SessionExpirationAware) {
      (repository as SessionExpirationAware).setSessionExpiredHandler(
        expireSession,
      );
    }
  }
  final ClientRepository repository;
  final SessionStore sessionStore;

  AuthSession? session;
  ClientBootstrap? data;
  LoadPhase phase = LoadPhase.idle;
  String? errorMessage;
  int navigationIndex = 0;
  bool loginInProgress = false;
  bool tenantLinkRefreshInProgress = false;
  bool tenantLinkInProgress = false;
  String? tenantLinkError;
  String? redeemingRewardId;
  bool initialized = false;
  final Map<String, String> _redemptionKeys = {};

  Future<void> initialize() async {
    if (initialized) return;
    try {
      final restored = await sessionStore.read();
      if (restored != null) {
        session = restored;
        phase = LoadPhase.loading;
        notifyListeners();
        data = await repository.loadBootstrap(restored);
        phase = LoadPhase.ready;
      }
    } on UnauthorizedException {
      await sessionStore.clear();
      session = null;
      data = null;
      phase = LoadPhase.idle;
    } on AppException catch (error) {
      if (_isTenantLinkRequired(error)) {
        phase = LoadPhase.tenantLinkRequired;
        errorMessage = error.message;
      } else if (session != null) {
        phase = LoadPhase.failure;
        errorMessage = error.message;
      }
    } catch (_) {
      if (session != null) {
        phase = LoadPhase.failure;
        errorMessage = 'Não foi possível restaurar sua sessão agora.';
      }
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({required String cpf, required String password}) async {
    if (loginInProgress) return false;
    loginInProgress = true;
    errorMessage = null;
    notifyListeners();
    try {
      session = await repository.login(cpf: cpf, password: password);
      await sessionStore.write(session!);
      phase = LoadPhase.loading;
      notifyListeners();
      data = await repository.loadBootstrap(session!);
      phase = LoadPhase.ready;
      return true;
    } on AppException catch (error) {
      if (_isTenantLinkRequired(error)) {
        phase = LoadPhase.tenantLinkRequired;
        errorMessage = 'Sua conta ainda não está vinculada a um condomínio.';
        return true;
      }
      phase = LoadPhase.failure;
      errorMessage = error.message;
      return false;
    } catch (_) {
      phase = LoadPhase.failure;
      errorMessage =
          'Não foi possível conectar. Verifique sua internet e tente novamente.';
      return false;
    } finally {
      loginInProgress = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final active = session;
    if (active == null || tenantLinkRefreshInProgress) return;
    final waitingForTenant = phase == LoadPhase.tenantLinkRequired;
    tenantLinkRefreshInProgress = waitingForTenant;
    if (!waitingForTenant) phase = LoadPhase.refreshing;
    errorMessage = null;
    notifyListeners();
    try {
      data = await repository.loadBootstrap(active);
      phase = LoadPhase.ready;
    } on AppException catch (error) {
      phase = _isTenantLinkRequired(error)
          ? LoadPhase.tenantLinkRequired
          : LoadPhase.ready;
      errorMessage = error.message;
    } catch (_) {
      phase = waitingForTenant ? LoadPhase.tenantLinkRequired : LoadPhase.ready;
      errorMessage = 'Não foi possível atualizar agora.';
    } finally {
      tenantLinkRefreshInProgress = false;
    }
    notifyListeners();
  }

  Future<bool> linkTenant(String invitationToken) async {
    final active = session;
    final token = invitationToken.trim();
    if (active == null || tenantLinkInProgress) return false;
    if (token.isEmpty || token.length > 200) {
      tenantLinkError = 'Informe um convite válido.';
      notifyListeners();
      return false;
    }
    tenantLinkInProgress = true;
    tenantLinkError = null;
    notifyListeners();
    try {
      final linkedSession = await repository.linkTenant(active, token);
      if (!identical(session, active)) return false;
      session = linkedSession;
      await sessionStore.write(linkedSession);
      data = await repository.loadBootstrap(linkedSession);
      if (!identical(session, linkedSession)) return false;
      phase = LoadPhase.ready;
      errorMessage = null;
      return true;
    } on AppException catch (error) {
      tenantLinkError = error.message;
      return false;
    } catch (_) {
      tenantLinkError =
          'Não foi possível vincular sua conta. Verifique sua conexão e tente novamente.';
      return false;
    } finally {
      tenantLinkInProgress = false;
      notifyListeners();
    }
  }

  void clearTenantLinkError() {
    if (tenantLinkError == null) return;
    tenantLinkError = null;
    notifyListeners();
  }

  bool _isTenantLinkRequired(AppException error) =>
      error.code == 'TENANT_LINK_REQUIRED' ||
      error.code == 'CONDOMINIUM_REQUIRED';

  void selectNavigation(int value) {
    navigationIndex = value;
    notifyListeners();
  }

  Future<void> logout() async {
    await sessionStore.clear();
    session = null;
    data = null;
    phase = LoadPhase.idle;
    errorMessage = null;
    navigationIndex = 0;
    tenantLinkRefreshInProgress = false;
    tenantLinkInProgress = false;
    tenantLinkError = null;
    _redemptionKeys.clear();
    notifyListeners();
  }

  Future<void> expireSession() async {
    if (session == null) return;
    await logout();
    errorMessage = 'Sua sessão expirou. Entre novamente.';
    notifyListeners();
  }

  Future<bool> redeemReward(String rewardId) async {
    final active = session;
    if (active == null || redeemingRewardId != null) return false;
    redeemingRewardId = rewardId;
    final key = _redemptionKeys.putIfAbsent(
      rewardId,
      () => '${DateTime.now().microsecondsSinceEpoch}-$rewardId',
    );
    notifyListeners();
    try {
      if (repository is ClientFeatureRepository) {
        final featureRepository = repository as ClientFeatureRepository;
        await featureRepository.redeemRewardWithKey(active, rewardId, key);
        final results = await Future.wait<Object>([
          featureRepository.loadLoyalty(active),
          featureRepository.loadRewards(active),
          featureRepository.loadCoupons(active),
        ]);
        data = data?.copyWith(
          loyalty: results.whereType<LoyaltySummary>().first,
          rewards: results.whereType<List<RewardSummary>>().first,
          coupons: results.whereType<List<CouponSummary>>().first,
        );
      } else {
        data = await repository.redeemReward(active, rewardId);
      }
      _redemptionKeys.remove(rewardId);
      errorMessage = null;
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Não foi possível resgatar a recompensa. Tente novamente.';
      return false;
    } finally {
      redeemingRewardId = null;
      notifyListeners();
    }
  }
}
