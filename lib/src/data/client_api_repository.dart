import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../domain/client_registration.dart';
import '../domain/models.dart';
import 'client_repository.dart';

class ClientApiRepository
    implements
        ClientRepository,
        ClientFeatureRepository,
        SessionExpirationAware {
  ClientApiRepository({
    required AppConfig config,
    http.Client? client,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _baseUrl = config.apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
       _client = client ?? http.Client(),
       _requestTimeout = requestTimeout;
  final String _baseUrl;
  final http.Client _client;
  final Duration _requestTimeout;
  SessionExpiredHandler? _sessionExpiredHandler;

  @override
  void setSessionExpiredHandler(SessionExpiredHandler handler) {
    _sessionExpiredHandler = handler;
  }

  @override
  Future<RegistrationLegalConfig> loadRegistrationLegalConfig() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/public/app-config'))
          .timeout(_requestTimeout);
      final body = _successfulBody(response);
      try {
        return RegistrationLegalConfig.fromJson(body);
      } on FormatException {
        throw const AppException(
          'Não foi possível validar os documentos legais disponíveis.',
        );
      }
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  @override
  Future<void> registerClient(ClientRegistrationRequest request) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw _registrationFailure(response);
    } on TimeoutException {
      throw const RegistrationException(
        kind: RegistrationFailureKind.network,
        code: 'REQUEST_TIMEOUT',
        message: 'A conexão demorou demais. Tente novamente.',
      );
    } on http.ClientException {
      throw const RegistrationException(
        kind: RegistrationFailureKind.network,
        code: 'NETWORK_UNAVAILABLE',
        message:
            'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.',
      );
    }
  }

  RegistrationException _registrationFailure(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = _decode(response);
    } on AppException {
      body = const <String, dynamic>{};
    }
    final code = body['code']?.toString();
    final rawFields = body['fieldErrors'];
    final fields = rawFields is Map
        ? rawFields.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : const <String, String>{};

    switch (code) {
      case 'CPF_ALREADY_REGISTERED':
        return const RegistrationException(
          kind: RegistrationFailureKind.cpfAlreadyRegistered,
          code: 'CPF_ALREADY_REGISTERED',
          message: 'Este CPF já possui uma conta.',
          fieldErrors: {'cpf': 'Este CPF já possui uma conta.'},
        );
      case 'EMAIL_ALREADY_REGISTERED':
        return const RegistrationException(
          kind: RegistrationFailureKind.emailAlreadyRegistered,
          code: 'EMAIL_ALREADY_REGISTERED',
          message: 'Este e-mail já está cadastrado.',
          fieldErrors: {'email': 'Este e-mail já está cadastrado.'},
        );
      case 'INVALID_CPF':
        return const RegistrationException(
          kind: RegistrationFailureKind.invalidCpf,
          code: 'INVALID_CPF',
          message: 'Confira o CPF informado.',
          fieldErrors: {'cpf': 'Confira o CPF informado.'},
        );
      case 'INVALID_REGISTRATION_DATA':
      case 'VALIDATION_ERROR':
        return RegistrationException(
          kind: RegistrationFailureKind.validation,
          code: code,
          message: 'Revise os dados informados.',
          fieldErrors: fields,
        );
      case 'REGISTRATION_RATE_LIMITED':
        return const RegistrationException(
          kind: RegistrationFailureKind.rateLimited,
          code: 'REGISTRATION_RATE_LIMITED',
          message: 'Muitas tentativas de cadastro. Tente novamente mais tarde.',
        );
    }
    if (response.statusCode >= 500) {
      return const RegistrationException(
        kind: RegistrationFailureKind.server,
        code: 'REGISTRATION_SERVER_ERROR',
        message:
            'Não foi possível criar sua conta agora. Tente novamente mais tarde.',
      );
    }
    return RegistrationException(
      kind: RegistrationFailureKind.unknown,
      code: code,
      message:
          'Não foi possível concluir o cadastro. Revise os dados e tente novamente.',
      fieldErrors: fields,
    );
  }

  @override
  Future<AuthSession> login({
    required String cpf,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'cpf': cpf, 'senha': password}),
        )
        .timeout(_requestTimeout);
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException(_friendlyMessage(response.statusCode));
    }
    final userJson = body['user'];
    final token = body['token']?.toString() ?? '';
    if (userJson is! Map<String, dynamic> || token.isEmpty) {
      throw const AppException(
        'Não foi possível validar sua sessão. Tente novamente.',
      );
    }
    return AuthSession(token: token, user: ClientUser.fromJson(userJson));
  }

  @override
  Future<void> requestPasswordRecovery(String cpf) async {
    await _postPublicJson('/user/recuperar', {'cpf': cpf});
  }

  @override
  Future<String> validatePasswordRecoveryCode(String cpf, String code) async {
    final body = await _postPublicJson('/user/validar', {
      'cpf': cpf,
      'code': code,
    });
    final token = body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw const AppException(
        'Não foi possível validar o código. Solicite um novo código.',
        code: 'PASSWORD_RESET_INVALID',
      );
    }
    return token;
  }

  @override
  Future<void> resetPassword({
    required String cpf,
    required String resetToken,
    required String newPassword,
  }) async {
    await _postPublicJson('/user/redefinir-senha', {
      'cpf': cpf,
      'token': resetToken,
      'novaSenha': newPassword,
    });
  }

  @override
  Future<AuthSession> linkTenant(
    AuthSession session,
    String invitationToken,
  ) async {
    final body = await _postJson('/app-cliente/tenant-link', session, {
      'token': invitationToken.trim(),
    }, errorMessage: _tenantLinkMessage);
    final token = body['accessToken']?.toString() ?? '';
    if (body['status']?.toString() != 'LINKED' || token.isEmpty) {
      throw const AppException(
        'O servidor não confirmou a vinculação. Tente novamente.',
      );
    }
    return AuthSession(token: token, user: session.user);
  }

  @override
  Future<ClientBootstrap> loadBootstrap(AuthSession session) async {
    final bootstrap = await _get('/app-cliente/bootstrap', session);
    final userJson = bootstrap['user'];
    final condominiumJson = bootstrap['condominio'];
    final featuresJson = bootstrap['features'];
    final capabilities = featuresJson is Map
        ? ClientCapabilities.fromJson(Map<String, dynamic>.from(featuresJson))
        : const ClientCapabilities();
    final results = await Future.wait<Object?>([
      loadPurchasePage(session),
      if (capabilities.catalog) loadCatalog(session, size: 20),
      if (capabilities.loyalty) loadLoyalty(session),
      if (capabilities.rewards) loadRewards(session),
      if (capabilities.coupons) loadCoupons(session),
    ]);
    final purchases = results.whereType<PageResult<PurchaseSummary>>().first;
    return ClientBootstrap(
      user: userJson is Map
          ? _bootstrapUser(Map<String, dynamic>.from(userJson), session.user)
          : session.user,
      capabilities: capabilities,
      purchases: purchases.content,
      condominium: condominiumJson is Map
          ? CondominiumSummary.fromJson(
              Map<String, dynamic>.from(condominiumJson),
            )
          : null,
      products: results
          .whereType<PageResult<ProductSummary>>()
          .expand((page) => page.content)
          .toList(),
      loyalty: results.whereType<LoyaltySummary>().firstOrNull,
      rewards: results
          .whereType<List<RewardSummary>>()
          .expand((e) => e)
          .toList(),
      coupons: results
          .whereType<List<CouponSummary>>()
          .expand((e) => e)
          .toList(),
      loyaltyMode: parseLoyaltyMode(bootstrap['loyaltyMode']?.toString()),
      serverTime: DateTime.tryParse(bootstrap['serverTime']?.toString() ?? ''),
    );
  }

  @override
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session) async {
    return (await loadPurchasePage(session, size: 50)).content;
  }

  Future<Map<String, dynamic>> _get(String path, AuthSession session) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {'Authorization': 'Bearer ${session.token}'},
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      return _successfulBody(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  Future<Map<String, dynamic>> _post(String path, AuthSession session) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Authorization': 'Bearer ${session.token}'},
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      return _successfulBody(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    AuthSession session,
    Map<String, Object?> payload, {
    String Function(int status, String? code)? errorMessage,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Authorization': 'Bearer ${session.token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      final body = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final code = body['code']?.toString();
        throw AppException(
          (errorMessage ?? _apiMessage)(response.statusCode, code),
          code: code,
          statusCode: response.statusCode,
        );
      }
      return body;
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    AuthSession session,
    Map<String, Object?> payload,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Authorization': 'Bearer ${session.token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      return _successfulBody(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  Future<List<dynamic>> _getList(String path, AuthSession session) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {'Authorization': 'Bearer ${session.token}'},
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = _decode(response);
        throw AppException(
          _apiMessage(response.statusCode, body['code']?.toString()),
          code: body['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      if (value is! List) {
        throw const AppException('O servidor enviou uma resposta inválida.');
      }
      return value;
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    } on FormatException {
      throw const AppException('O servidor enviou uma resposta inválida.');
    }
  }

  Future<ReceiptImage> _getReceipt(String path, AuthSession session) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {'Authorization': 'Bearer ${session.token}'},
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = _decode(response);
        throw AppException(
          _apiMessage(response.statusCode, body['code']?.toString()),
          code: body['code']?.toString(),
          statusCode: response.statusCode,
        );
      }
      final type = response.headers['content-type'] ?? '';
      if (!type.toLowerCase().contains('image/png') ||
          response.bodyBytes.isEmpty) {
        throw const AppException('O comprovante recebido é inválido.');
      }
      return ReceiptImage(bytes: response.bodyBytes);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  Future<void> _expireSessionIfNeeded(http.Response response) async {
    if (response.statusCode != 401) return;
    await _sessionExpiredHandler?.call();
    throw const UnauthorizedException();
  }

  Future<Map<String, dynamic>> _postPublicJson(
    String path,
    Map<String, Object?> payload,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
      final body = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final code = body['code']?.toString();
        throw AppException(
          _passwordRecoveryMessage(response.statusCode, code),
          code: code,
          statusCode: response.statusCode,
        );
      }
      return body;
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  Map<String, dynamic> _successfulBody(http.Response response) {
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = body['code']?.toString();
      throw AppException(
        _apiMessage(response.statusCode, code),
        code: code,
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } on FormatException {
      throw const AppException('O servidor enviou uma resposta inválida.');
    }
  }

  String _friendlyMessage(int status) {
    if (status == 401 || status == 403) {
      return 'CPF ou senha inválidos.';
    }
    if (status >= 500) {
      return 'Nosso serviço está indisponível no momento. Tente novamente.';
    }
    return 'Não foi possível concluir a solicitação.';
  }

  String _apiMessage(int status, String? code) {
    if (status == 401) return 'Sua sessão expirou. Entre novamente.';
    if (code == 'TENANT_LINK_REQUIRED' || code == 'CONDOMINIUM_REQUIRED') {
      return 'Sua conta ainda não está vinculada a um condomínio.';
    }
    if (code == 'CUSTOMER_QR_DISABLED') {
      return 'A identificação por QR não está disponível neste condomínio.';
    }
    if (status == 403) {
      return 'Sua conta não tem permissão para gerar este QR.';
    }
    if (status >= 500) {
      return 'Nosso serviço está indisponível no momento. Tente novamente.';
    }
    return 'Não foi possível gerar seu QR. Tente novamente.';
  }

  String _tenantLinkMessage(int status, String? code) {
    if (status == 401) return 'Sua sessão expirou. Entre novamente.';
    if (code == 'TENANT_INVITATION_INVALID') {
      return 'Este convite é inválido, expirou ou não pertence à sua conta.';
    }
    if (code == 'TENANT_LINK_ALREADY_EXISTS') {
      return 'Sua conta já está vinculada a um condomínio.';
    }
    if (status >= 500) {
      return 'Não foi possível vincular sua conta agora. Tente novamente.';
    }
    return 'Não foi possível usar este convite. Confira e tente novamente.';
  }

  String _passwordRecoveryMessage(int status, String? code) {
    if (code == 'PASSWORD_RESET_INVALID') {
      return 'Código ou solicitação inválida ou expirada.';
    }
    if (code == 'PASSWORD_RESET_RATE_LIMITED' || status == 429) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (status >= 500) {
      return 'Não foi possível acessar a recuperação de senha agora.';
    }
    return 'Não foi possível concluir a recuperação. Revise os dados.';
  }

  ClientUser _bootstrapUser(Map<String, dynamic> json, ClientUser fallback) {
    final fullName = json['nome']?.toString().trim() ?? '';
    final parts = fullName.split(RegExp(r'\s+'));
    return ClientUser(
      id: json['id']?.toString() ?? fallback.id,
      firstName: parts.isEmpty || parts.first.isEmpty
          ? fallback.firstName
          : parts.first,
      lastName: parts.length > 1
          ? parts.sublist(1).join(' ')
          : fallback.lastName,
      email: json['email']?.toString() ?? fallback.email,
      cpf: json['cpf']?.toString() ?? fallback.cpf,
      phone: fallback.phone,
      photoUrl: fallback.photoUrl,
    );
  }

  @override
  Future<PageResult<ProductSummary>> loadCatalog(
    AuthSession session, {
    String? query,
    String? category,
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/app-cliente/catalogo').replace(
      queryParameters: {
        if (query?.trim().isNotEmpty == true) 'busca': query!.trim(),
        if (category?.trim().isNotEmpty == true) 'categoria': category!.trim(),
        'page': '$page',
        'size': '$size',
      },
    );
    final json = await _get(uri.toString().replaceFirst(_baseUrl, ''), session);
    return _page(json, ProductSummary.fromJson);
  }

  @override
  Future<PageResult<PurchaseSummary>> loadPurchasePage(
    AuthSession session, {
    int page = 0,
    int size = 20,
  }) async {
    final json = await _get(
      '/app-cliente/compras?page=$page&size=$size',
      session,
    );
    return _page(json, PurchaseSummary.fromJson);
  }

  PageResult<T> _page<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final raw = json['content'];
    return PageResult<T>(
      content: raw is List
          ? raw
                .whereType<Map>()
                .map((item) => parser(Map<String, dynamic>.from(item)))
                .toList()
          : <T>[],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<PurchaseDetail> loadPurchase(
    AuthSession session,
    String purchaseId,
  ) async => PurchaseDetail.fromJson(
    await _get('/app-cliente/compras/$purchaseId', session),
  );

  @override
  Future<ReceiptImage> loadReceipt(AuthSession session, String purchaseId) =>
      _getReceipt('/app-cliente/compras/$purchaseId/comprovante', session);

  @override
  Future<void> sendReceipt(
    AuthSession session,
    String purchaseId, {
    required String channel,
    required String recipient,
  }) async {
    await _postJson(
      '/app-cliente/compras/$purchaseId/comprovante/envios',
      session,
      {'canal': channel, 'destinatario': recipient},
    );
  }

  @override
  Future<SupportResult> requestPurchaseSupport(
    AuthSession session,
    String purchaseId, {
    required String category,
    required String message,
  }) async => SupportResult.fromJson(
    await _postJson('/app-cliente/compras/$purchaseId/suporte', session, {
      'categoria': category,
      'mensagem': message,
    }),
  );

  @override
  Future<LoyaltySummary> loadLoyalty(AuthSession session) async =>
      LoyaltySummary.fromJson(await _get('/app-cliente/fidelidade', session));

  @override
  Future<List<RewardSummary>> loadRewards(AuthSession session) async =>
      (await _getList('/app-cliente/recompensas', session))
          .whereType<Map>()
          .map(
            (item) => RewardSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

  @override
  Future<RedemptionResult> redeemRewardWithKey(
    AuthSession session,
    String rewardId,
    String idempotencyKey,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/app-cliente/recompensas/$rewardId/resgates'),
            headers: {
              'Authorization': 'Bearer ${session.token}',
              'Idempotency-Key': idempotencyKey,
            },
          )
          .timeout(_requestTimeout);
      await _expireSessionIfNeeded(response);
      return RedemptionResult.fromJson(_successfulBody(response));
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }
  }

  @override
  Future<List<CouponSummary>> loadCoupons(AuthSession session) async =>
      (await _getList('/app-cliente/cupons', session))
          .whereType<Map>()
          .map(
            (item) => CouponSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

  @override
  Future<PreferenceSettings> loadPreferences(AuthSession session) async =>
      PreferenceSettings.fromJson(
        await _get('/app-cliente/preferencias', session),
      );

  @override
  Future<PreferenceSettings> updatePreferences(
    AuthSession session,
    PreferenceSettings preferences,
  ) async => PreferenceSettings.fromJson(
    await _putJson('/app-cliente/preferencias', session, {
      'autoEmail': preferences.autoEmail,
      'autoWhatsapp': preferences.autoWhatsapp,
    }),
  );

  @override
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) async {
    final json = await _post('/app-cliente/identificacao-tokens', session);
    try {
      return CustomerIdentificationToken.fromJson(json);
    } on FormatException {
      throw const AppException('O servidor enviou uma resposta inválida.');
    }
  }

  @override
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  ) async => TemporaryQrToken.fromJson(
    await _post('/app-cliente/cupons/$couponId/tokens', session),
  );

  @override
  Future<ClientBootstrap> redeemReward(
    AuthSession session,
    String rewardId,
  ) async {
    final key = '${DateTime.now().microsecondsSinceEpoch}-$rewardId';
    await redeemRewardWithKey(session, rewardId, key);
    return loadBootstrap(session);
  }
}
