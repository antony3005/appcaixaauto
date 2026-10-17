import 'dart:convert';
import 'dart:typed_data';

import 'package:appcaixaauto/src/core/config/app_config.dart';
import 'package:appcaixaauto/src/data/client_api_repository.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const session = AuthSession(
    token: 'jwt-contract-test',
    user: ClientUser(
      id: 'user-1',
      firstName: 'Ana',
      lastName: 'Silva',
      email: 'ana@example.test',
      cpf: '52998224725',
      phone: '5575999999999',
    ),
  );

  test(
    'catálogo envia filtros/paginação e interpreta promoção Spring',
    () async {
      late http.Request captured;
      final repository = _repository(
        MockClient((request) async {
          captured = request;
          return _json({
            'content': [
              {
                'id': 'produto-1',
                'nome': 'Café 500 g',
                'descricao': 'Torrado e moído',
                'foto': 'https://cdn.example.test/cafe.png',
                'categoria': 'MERCEARIA',
                'unidade': 'UNIDADE',
                'precoOriginal': 22.50,
                'precoFinal': 18.90,
                'promocao': {
                  'id': 'promo-1',
                  'nome': 'Semana do café',
                  'tipo': 'PERCENTUAL',
                  'valor': 16,
                },
              },
            ],
            'page': 1,
            'size': 10,
            'totalElements': 21,
            'totalPages': 3,
          });
        }),
      );

      final page = await repository.loadCatalog(
        session,
        query: ' café ',
        category: 'MERCEARIA',
        page: 1,
        size: 10,
      );

      expect(captured.url.path, '/app-cliente/catalogo');
      expect(captured.url.queryParameters['busca'], 'café');
      expect(captured.url.queryParameters['categoria'], 'MERCEARIA');
      expect(captured.url.queryParameters['page'], '1');
      expect(page.hasMore, isTrue);
      expect(page.content.single.price, 18.90);
      expect(page.content.single.originalPrice, 22.50);
      expect(page.content.single.isPromotion, isTrue);
    },
  );

  test(
    'detalhe de compra interpreta itens, descontos e paidAt reais',
    () async {
      final repository = _repository(
        MockClient(
          (_) async => _json({
            'id': 'order-1',
            'status': 'PROCESSED',
            'subtotal': 25.40,
            'desconto': 1.93,
            'total': 23.47,
            'createdAt': '2026-09-13T18:42:00Z',
            'paidAt': '2026-09-13T18:43:00Z',
            'items': [
              {
                'id': 'item-1',
                'produtoId': 'produto-1',
                'codigoInterno': 'CAF-01',
                'codigoBarras': '7890000000001',
                'nome': 'Café 500 g',
                'unidade': 'UNIDADE',
                'quantidade': 1,
                'precoOriginal': 25.40,
                'precoFinal': 23.47,
                'tipoPromocao': 'PERCENTUAL',
                'valorPromocao': 7.6,
                'desconto': 1.93,
                'subtotal': 23.47,
              },
            ],
          }),
        ),
      );

      final detail = await repository.loadPurchase(session, 'order-1');

      expect(detail.status, PurchaseStatus.approved);
      expect(detail.paidAt, DateTime.parse('2026-09-13T18:43:00Z'));
      expect(detail.items.single.name, 'Café 500 g');
      expect(detail.items.single.discount, 1.93);
      expect(detail.total, 23.47);
    },
  );

  test('comprovante mantém resposta image/png binária', () async {
    final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    final repository = _repository(
      MockClient(
        (_) async => http.Response.bytes(
          bytes,
          200,
          headers: {'content-type': 'image/png'},
        ),
      ),
    );

    final receipt = await repository.loadReceipt(session, 'order-1');

    expect(receipt.bytes, bytes);
  });

  test('fidelidade, recompensa e cupons preservam modos e estados', () async {
    final repository = _repository(
      MockClient((request) async {
        if (request.url.path.endsWith('/fidelidade')) {
          return _json({
            'enabled': true,
            'mode': 'POINTS',
            'pointsBalance': 1240,
            'cashbackBalance': null,
            'nextReward': null,
            'movements': [
              {
                'id': 'mov-1',
                'type': 'PURCHASE',
                'pointsDelta': 50,
                'cashbackDelta': null,
                'description': 'Compra #order-1',
                'createdAt': '2026-09-13T18:43:00Z',
              },
            ],
          });
        }
        if (request.url.path.endsWith('/recompensas')) {
          return _json([
            {
              'id': 'reward-1',
              'nome': '10% OFF',
              'tipoDesconto': 'PERCENTUAL',
              'valorDesconto': 10,
              'custoPontos': 500,
              'valorMinimoCompra': 100,
              'descontoMaximo': 25,
              'validade': '2026-12-31T23:59:59Z',
              'eligible': false,
              'unavailableReason': 'INSUFFICIENT_POINTS',
            },
          ]);
        }
        return _json([
          {
            'id': 'coupon-1',
            'nome': 'R\$ 10 OFF',
            'tipo': 'VALOR_FIXO',
            'valor': 10,
            'valorMinimoCompra': 40,
            'descontoMaximo': null,
            'validade': '2026-12-31T23:59:59Z',
            'status': 'RESERVED',
          },
          {
            'id': 'coupon-2',
            'nome': 'Expirado',
            'tipo': 'PERCENTUAL',
            'valor': 5,
            'valorMinimoCompra': 20,
            'descontoMaximo': 10,
            'validade': '2025-01-01T00:00:00Z',
            'status': 'CANCELLED',
          },
        ]);
      }),
    );

    final loyalty = await repository.loadLoyalty(session);
    final rewards = await repository.loadRewards(session);
    final coupons = await repository.loadCoupons(session);

    expect(loyalty.mode, LoyaltyMode.points);
    expect(loyalty.movements.single.pointsDelta, 50);
    expect(rewards.single.discountType, RewardDiscountType.percentage);
    expect(rewards.single.available, isFalse);
    expect(coupons.map((coupon) => coupon.status), [
      CouponStatus.reserved,
      CouponStatus.cancelled,
    ]);
  });

  test('resgate envia a mesma Idempotency-Key fornecida', () async {
    late http.Request captured;
    final repository = _repository(
      MockClient((request) async {
        captured = request;
        return _json({
          'id': 'redemption-1',
          'couponId': 'coupon-1',
          'status': 'COMPLETED',
        }, status: 201);
      }),
    );

    final result = await repository.redeemRewardWithKey(
      session,
      'reward-1',
      'logical-attempt-123',
    );

    expect(captured.headers['Idempotency-Key'], 'logical-attempt-123');
    expect(captured.body, isEmpty);
    expect(result.couponId, 'coupon-1');
  });

  test('QR de cupom exige token, expiresAt e serverTime do servidor', () async {
    final repository = _repository(
      MockClient(
        (_) async => _json({
          'token': 'opaque-coupon-token',
          'expiresAt': '2026-10-01T12:02:00Z',
          'serverTime': '2026-10-01T12:00:00Z',
        }, status: 201),
      ),
    );

    final token = await repository.createCouponToken(session, 'coupon-1');

    expect(token.value, 'opaque-coupon-token');
    expect(
      token.expiresAt.difference(token.serverTime!),
      const Duration(minutes: 2),
    );
  });

  test('preferências e suporte enviam somente campos do contrato', () async {
    final requests = <http.Request>[];
    final repository = _repository(
      MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/preferencias')) {
          return _json({'autoEmail': true, 'autoWhatsapp': false});
        }
        return _json({
          'protocolo': 'SUP-20261001-123456',
          'status': 'OPEN',
        }, status: 201);
      }),
    );

    final preferences = await repository.updatePreferences(
      session,
      const PreferenceSettings(autoEmail: true, autoWhatsapp: false),
    );
    final support = await repository.requestPurchaseSupport(
      session,
      'order-1',
      category: 'Item divergente',
      message: 'O valor cobrado está diferente.',
    );

    expect(jsonDecode(requests.first.body), {
      'autoEmail': true,
      'autoWhatsapp': false,
    });
    expect(jsonDecode(requests.last.body), {
      'categoria': 'Item divergente',
      'mensagem': 'O valor cobrado está diferente.',
    });
    expect(preferences.autoEmail, isTrue);
    expect(support.protocol, 'SUP-20261001-123456');
  });

  test('recuperação usa CPF, código e senha de 8+ no contrato real', () async {
    final requests = <http.Request>[];
    final repository = _repository(
      MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/validar')) {
          return _json({'token': 'one-use-reset-token'});
        }
        return _json({
          'message': 'ok',
        }, status: request.url.path.endsWith('/recuperar') ? 202 : 200);
      }),
    );

    await repository.requestPasswordRecovery('52998224725');
    final resetToken = await repository.validatePasswordRecoveryCode(
      '52998224725',
      '123456',
    );
    await repository.resetPassword(
      cpf: '52998224725',
      resetToken: resetToken,
      newPassword: 'novaSenha8',
    );

    expect(requests.map((request) => request.url.path), [
      '/user/recuperar',
      '/user/validar',
      '/user/redefinir-senha',
    ]);
    expect(jsonDecode(requests.last.body), {
      'cpf': '52998224725',
      'token': 'one-use-reset-token',
      'novaSenha': 'novaSenha8',
    });
  });

  test('401 autenticado dispara expiração global antes do erro', () async {
    var expired = false;
    final repository = _repository(
      MockClient((_) async => _json({'code': 'AUTH_REQUIRED'}, status: 401)),
    )..setSessionExpiredHandler(() async => expired = true);

    await expectLater(
      repository.loadPreferences(session),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(expired, isTrue);
  });
}

ClientApiRepository _repository(http.Client client) => ClientApiRepository(
  config: const AppConfig(apiBaseUrl: 'https://api.example.test'),
  client: client,
);

http.Response _json(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
