import 'dart:typed_data';

enum LoadPhase { idle, loading, ready, refreshing, tenantLinkRequired, failure }

class AuthSession {
  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString() ?? '';
    final user = json['user'];
    if (token.isEmpty || user is! Map) {
      throw const FormatException('Invalid stored session');
    }
    return AuthSession(
      token: token,
      user: ClientUser.fromStoredJson(Map<String, dynamic>.from(user)),
    );
  }

  final String token;
  final ClientUser user;

  Map<String, Object?> toJson() => {'token': token, 'user': user.toJson()};
}

class ClientUser {
  const ClientUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cpf,
    required this.phone,
    this.photoUrl,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) => ClientUser(
    id: (json['userId'] ?? json['id'])?.toString() ?? '',
    firstName: json['nome']?.toString() ?? '',
    lastName: json['sobrenome']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    cpf: json['cpf']?.toString() ?? '',
    phone: json['telefone']?.toString() ?? '',
    photoUrl: json['fotoPerfil']?.toString(),
  );

  factory ClientUser.fromStoredJson(Map<String, dynamic> json) => ClientUser(
    id: json['id']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    cpf: json['cpf']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    photoUrl: json['photoUrl']?.toString(),
  );

  final String id, firstName, lastName, email, cpf, phone;
  final String? photoUrl;
  String get fullName => '$firstName $lastName'.trim();

  Map<String, Object?> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'cpf': cpf,
    'phone': phone,
    'photoUrl': photoUrl,
  };
}

class ClientCapabilities {
  const ClientCapabilities({
    this.catalog = false,
    this.promotions = false,
    this.identificationQr = false,
    this.loyalty = false,
    this.points = false,
    this.cashback = false,
    this.rewards = false,
    this.coupons = false,
    this.preferences = false,
    this.purchaseSupport = false,
  });

  factory ClientCapabilities.fromJson(Map<String, dynamic> json) =>
      ClientCapabilities(
        catalog: json['catalogo'] == true,
        promotions: json['promocoes'] == true,
        identificationQr: json['qrIdentificacao'] == true,
        loyalty: json['fidelidade'] == true,
        points: json['pontos'] == true,
        cashback: json['cashback'] == true,
        rewards: json['recompensas'] == true,
        coupons: json['cupons'] == true,
        preferences: json['preferencias'] == true,
        purchaseSupport: json['suporte'] == true,
      );

  final bool catalog,
      promotions,
      identificationQr,
      loyalty,
      points,
      cashback,
      rewards,
      coupons,
      preferences,
      purchaseSupport;
  bool get benefits => loyalty && (points || cashback || rewards || coupons);
}

class CondominiumSummary {
  const CondominiumSummary({required this.id, required this.name});
  factory CondominiumSummary.fromJson(Map<String, dynamic> json) =>
      CondominiumSummary(
        id: json['id']?.toString() ?? '',
        name: json['nome']?.toString() ?? '',
      );
  final String id, name;
}

enum LoyaltyMode { none, points, cashback }

LoyaltyMode parseLoyaltyMode(String? raw) => switch (raw?.toUpperCase()) {
  'POINTS' => LoyaltyMode.points,
  'CASHBACK' => LoyaltyMode.cashback,
  _ => LoyaltyMode.none,
};

class PageResult<T> {
  const PageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });
  final List<T> content;
  final int page, size, totalElements, totalPages;
  bool get hasMore => page + 1 < totalPages;
}

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    this.originalPrice,
    this.description,
    this.imageUrl,
    this.promotionName,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final promotion = json['promocao'];
    return ProductSummary(
      id: json['id']?.toString() ?? '',
      name: json['nome']?.toString() ?? '',
      description: json['descricao']?.toString(),
      imageUrl: json['foto']?.toString(),
      category: json['categoria']?.toString() ?? '',
      unit: json['unidade']?.toString() ?? '',
      originalPrice: _nullableNumber(json['precoOriginal']),
      price: _number(json['precoFinal']),
      promotionName: promotion is Map ? promotion['nome']?.toString() : null,
    );
  }

  final String id, name, category, unit;
  final double price;
  final double? originalPrice;
  final String? description, imageUrl, promotionName;
  bool get isPromotion => originalPrice != null && originalPrice! > price;
  bool get isAvailable => price >= 0;
}

enum PurchaseStatus {
  pending,
  created,
  atTerminal,
  approved,
  canceled,
  expired,
  failed,
  refunded,
  actionRequired,
  unknown,
}

class PurchaseSummary {
  const PurchaseSummary({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.createdAt,
    this.paidAt,
    this.condominiumName,
    this.itemCount,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) =>
      PurchaseSummary(
        id: (json['id'] ?? json['orderId'])?.toString() ?? '',
        status: parsePurchaseStatus(json['status']?.toString()),
        subtotal: _number(json['subtotal']),
        discount: _number(json['desconto']),
        total: _number(json['total']),
        createdAt: _date(json['createdAt']),
        paidAt: _nullableDate(json['paidAt']),
        itemCount: _nullableInt(json['itemCount']),
        condominiumName: json['condominiumName']?.toString(),
      );

  final String id;
  final PurchaseStatus status;
  final double subtotal, discount, total;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? condominiumName;
  final int? itemCount;
}

class PurchaseItem {
  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.originalPrice,
    required this.finalPrice,
    required this.discount,
    required this.subtotal,
    this.internalCode,
    this.barcode,
    this.promotionType,
    this.promotionValue,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    id: json['id']?.toString() ?? '',
    productId: json['produtoId']?.toString() ?? '',
    internalCode: json['codigoInterno']?.toString(),
    barcode: json['codigoBarras']?.toString(),
    name: json['nome']?.toString() ?? '',
    unit: json['unidade']?.toString() ?? '',
    quantity: _number(json['quantidade']),
    originalPrice: _number(json['precoOriginal']),
    finalPrice: _number(json['precoFinal']),
    promotionType: json['tipoPromocao']?.toString(),
    promotionValue: _nullableNumber(json['valorPromocao']),
    discount: _number(json['desconto']),
    subtotal: _number(json['subtotal']),
  );

  final String id, productId, name, unit;
  final String? internalCode, barcode, promotionType;
  final double quantity, originalPrice, finalPrice, discount, subtotal;
  final double? promotionValue;
}

class PurchaseDetail {
  const PurchaseDetail({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.createdAt,
    required this.items,
    this.paidAt,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) => PurchaseDetail(
    id: json['id']?.toString() ?? '',
    status: parsePurchaseStatus(json['status']?.toString()),
    subtotal: _number(json['subtotal']),
    discount: _number(json['desconto']),
    total: _number(json['total']),
    createdAt: _date(json['createdAt']),
    paidAt: _nullableDate(json['paidAt']),
    items: _mapList(json['items'], PurchaseItem.fromJson),
  );

  final String id;
  final PurchaseStatus status;
  final double subtotal, discount, total;
  final DateTime createdAt;
  final DateTime? paidAt;
  final List<PurchaseItem> items;
}

PurchaseStatus parsePurchaseStatus(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'pending':
      return PurchaseStatus.pending;
    case 'created':
      return PurchaseStatus.created;
    case 'at_terminal':
      return PurchaseStatus.atTerminal;
    case 'processed':
    case 'approved':
    case 'paid':
      return PurchaseStatus.approved;
    case 'canceled':
    case 'cancelled':
      return PurchaseStatus.canceled;
    case 'expired':
      return PurchaseStatus.expired;
    case 'failed':
      return PurchaseStatus.failed;
    case 'refunded':
      return PurchaseStatus.refunded;
    case 'action_required':
      return PurchaseStatus.actionRequired;
    default:
      return PurchaseStatus.unknown;
  }
}

class LoyaltyMovement {
  const LoyaltyMovement({
    required this.id,
    required this.type,
    required this.description,
    required this.createdAt,
    this.pointsDelta,
    this.cashbackDelta,
  });

  factory LoyaltyMovement.fromJson(Map<String, dynamic> json) =>
      LoyaltyMovement(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        pointsDelta: _nullableInt(json['pointsDelta']),
        cashbackDelta: _nullableNumber(json['cashbackDelta']),
        description: json['description']?.toString() ?? '',
        createdAt: _date(json['createdAt']),
      );

  final String id, type, description;
  final int? pointsDelta;
  final double? cashbackDelta;
  final DateTime createdAt;
}

class LoyaltySummary {
  const LoyaltySummary({
    this.enabled = true,
    this.mode = LoyaltyMode.none,
    this.points,
    this.cashback,
    this.nextReward,
    this.nextRewardPoints,
    this.couponsAvailable = 0,
    this.movements = const [],
  });

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) => LoyaltySummary(
    enabled: json['enabled'] == true,
    mode: parseLoyaltyMode(json['mode']?.toString()),
    points: _nullableInt(json['pointsBalance']),
    cashback: _nullableNumber(json['cashbackBalance']),
    nextReward: json['nextReward'] is Map
        ? RewardSummary.fromJson(
            Map<String, dynamic>.from(json['nextReward'] as Map),
          )
        : null,
    movements: _mapList(json['movements'], LoyaltyMovement.fromJson),
  );

  final bool enabled;
  final LoyaltyMode mode;
  final int? points, nextRewardPoints;
  final double? cashback;
  final RewardSummary? nextReward;
  final int couponsAvailable;
  final List<LoyaltyMovement> movements;
}

enum RewardDiscountType { percentage, fixedValue, unknown }

class RewardSummary {
  const RewardSummary({
    required this.id,
    required this.title,
    required this.pointsCost,
    required this.minimumPurchase,
    this.discountType = RewardDiscountType.unknown,
    this.discountValue = 0,
    this.maximumDiscount,
    this.validUntil,
    this.available = true,
    this.unavailableReason,
  });

  factory RewardSummary.fromJson(Map<String, dynamic> json) => RewardSummary(
    id: json['id']?.toString() ?? '',
    title: json['nome']?.toString() ?? '',
    discountType: switch (json['tipoDesconto']?.toString()) {
      'PERCENTUAL' => RewardDiscountType.percentage,
      'VALOR_FIXO' => RewardDiscountType.fixedValue,
      _ => RewardDiscountType.unknown,
    },
    discountValue: _number(json['valorDesconto']),
    pointsCost: _int(json['custoPontos']),
    minimumPurchase: _number(json['valorMinimoCompra']),
    maximumDiscount: _nullableNumber(json['descontoMaximo']),
    validUntil: _nullableDate(json['validade']),
    available: json['eligible'] != false,
    unavailableReason: json['unavailableReason']?.toString(),
  );

  final String id, title;
  final RewardDiscountType discountType;
  final double discountValue;
  final int pointsCost;
  final double minimumPurchase;
  final double? maximumDiscount;
  final DateTime? validUntil;
  final bool available;
  final String? unavailableReason;
}

enum CouponStatus { available, reserved, used, expired, cancelled, unknown }

class CouponSummary {
  const CouponSummary({
    required this.id,
    required this.title,
    required this.minimumPurchase,
    required this.validUntil,
    required this.status,
    this.type = '',
    this.value = 0,
    this.maximumDiscount,
  });

  factory CouponSummary.fromJson(Map<String, dynamic> json) => CouponSummary(
    id: json['id']?.toString() ?? '',
    title: json['nome']?.toString() ?? '',
    type: json['tipo']?.toString() ?? '',
    value: _number(json['valor']),
    minimumPurchase: _number(json['valorMinimoCompra']),
    maximumDiscount: _nullableNumber(json['descontoMaximo']),
    validUntil: _date(json['validade']),
    status: switch (json['status']?.toString()) {
      'AVAILABLE' => CouponStatus.available,
      'RESERVED' => CouponStatus.reserved,
      'USED' => CouponStatus.used,
      'EXPIRED' => CouponStatus.expired,
      'CANCELLED' => CouponStatus.cancelled,
      _ => CouponStatus.unknown,
    },
  );

  final String id, title, type;
  final double value, minimumPurchase;
  final double? maximumDiscount;
  final DateTime validUntil;
  final CouponStatus status;
}

class PreferenceSettings {
  const PreferenceSettings({
    required this.autoEmail,
    required this.autoWhatsapp,
  });
  factory PreferenceSettings.fromJson(Map<String, dynamic> json) =>
      PreferenceSettings(
        autoEmail: json['autoEmail'] == true,
        autoWhatsapp: json['autoWhatsapp'] == true,
      );
  final bool autoEmail, autoWhatsapp;
}

class RedemptionResult {
  const RedemptionResult({
    required this.id,
    required this.couponId,
    required this.status,
  });
  factory RedemptionResult.fromJson(Map<String, dynamic> json) =>
      RedemptionResult(
        id: json['id']?.toString() ?? '',
        couponId: json['couponId']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );
  final String id, couponId, status;
}

class SupportResult {
  const SupportResult({required this.protocol, required this.status});
  factory SupportResult.fromJson(Map<String, dynamic> json) => SupportResult(
    protocol: json['protocolo']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
  );
  final String protocol, status;
}

class ReceiptImage {
  const ReceiptImage({required this.bytes});
  final Uint8List bytes;
}

class ClientBootstrap {
  const ClientBootstrap({
    required this.user,
    required this.capabilities,
    required this.purchases,
    this.condominium,
    this.products = const [],
    this.loyalty,
    this.rewards = const [],
    this.coupons = const [],
    this.loyaltyMode = LoyaltyMode.none,
    this.serverTime,
  });
  final ClientUser user;
  final ClientCapabilities capabilities;
  final CondominiumSummary? condominium;
  final List<ProductSummary> products;
  final List<PurchaseSummary> purchases;
  final LoyaltySummary? loyalty;
  final List<RewardSummary> rewards;
  final List<CouponSummary> coupons;
  final LoyaltyMode loyaltyMode;
  final DateTime? serverTime;

  ClientBootstrap copyWith({
    List<ProductSummary>? products,
    List<PurchaseSummary>? purchases,
    LoyaltySummary? loyalty,
    List<RewardSummary>? rewards,
    List<CouponSummary>? coupons,
  }) => ClientBootstrap(
    user: user,
    capabilities: capabilities,
    condominium: condominium,
    products: products ?? this.products,
    purchases: purchases ?? this.purchases,
    loyalty: loyalty ?? this.loyalty,
    rewards: rewards ?? this.rewards,
    coupons: coupons ?? this.coupons,
    loyaltyMode: loyalty?.mode ?? loyaltyMode,
    serverTime: serverTime,
  );
}

class TemporaryQrToken {
  const TemporaryQrToken({
    required this.value,
    required this.expiresAt,
    this.serverTime,
  });
  factory TemporaryQrToken.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString() ?? '';
    final expiresAt = _nullableDate(json['expiresAt']);
    final serverTime = _nullableDate(json['serverTime']);
    if (token.isEmpty || expiresAt == null || serverTime == null) {
      throw const FormatException('Invalid temporary token response');
    }
    return TemporaryQrToken(
      value: token,
      expiresAt: expiresAt,
      serverTime: serverTime,
    );
  }
  final String value;
  final DateTime expiresAt;
  final DateTime? serverTime;
}

class CustomerIdentificationToken {
  const CustomerIdentificationToken({
    required this.qrPayload,
    required this.expiresAt,
    required this.serverTime,
  });

  factory CustomerIdentificationToken.fromJson(Map<String, dynamic> json) {
    final payload = json['qrPayload']?.toString() ?? '';
    final expiresAt = _nullableDate(json['expiresAt']);
    final serverTime = _nullableDate(json['serverTime']);
    if (payload.isEmpty || expiresAt == null || serverTime == null) {
      throw const FormatException('Invalid customer identification response');
    }
    return CustomerIdentificationToken(
      qrPayload: payload,
      expiresAt: expiresAt,
      serverTime: serverTime,
    );
  }

  final String qrPayload;
  final DateTime expiresAt;
  final DateTime serverTime;
}

class AppException implements Exception {
  const AppException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException()
    : super(
        'Sua sessão expirou. Entre novamente.',
        code: 'SESSION_EXPIRED',
        statusCode: 401,
      );
}

class NetworkUnavailableException extends AppException {
  const NetworkUnavailableException()
    : super('Você está offline. Conecte-se à internet e tente novamente.');
}

class RequestTimeoutException extends AppException {
  const RequestTimeoutException()
    : super('A solicitação demorou demais. Tente novamente.');
}

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
double? _nullableNumber(dynamic value) => value == null
    ? null
    : value is num
    ? value.toDouble()
    : double.tryParse(value.toString());
int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
int? _nullableInt(dynamic value) => value == null
    ? null
    : value is num
    ? value.toInt()
    : int.tryParse(value.toString());
DateTime _date(dynamic value) =>
    _nullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
DateTime? _nullableDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '');
List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) parser) =>
    value is List
    ? value
          .whereType<Map>()
          .map((item) => parser(Map<String, dynamic>.from(item)))
          .toList()
    : <T>[];
