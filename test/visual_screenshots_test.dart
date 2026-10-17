import 'dart:io';
import 'dart:ui' as ui;

import 'package:appcaixaauto/src/app.dart';
import 'package:appcaixaauto/src/core/theme/app_theme.dart';
import 'package:appcaixaauto/src/data/client_repository.dart';
import 'package:appcaixaauto/src/domain/client_registration.dart';
import 'package:appcaixaauto/src/domain/models.dart';
import 'package:appcaixaauto/src/features/auth/login_page.dart';
import 'package:appcaixaauto/src/features/auth/password_recovery_page.dart';
import 'package:appcaixaauto/src/features/auth/registration_page.dart';
import 'package:appcaixaauto/src/features/benefits/benefits_page.dart';
import 'package:appcaixaauto/src/features/catalog/catalog_pages.dart';
import 'package:appcaixaauto/src/features/profile/profile_page.dart';
import 'package:appcaixaauto/src/features/purchases/purchases_page.dart';
import 'package:appcaixaauto/src/features/qr/customer_identification_page.dart';
import 'package:appcaixaauto/src/features/qr/temporary_qr_page.dart';
import 'package:appcaixaauto/src/features/shell/client_shell.dart';
import 'package:appcaixaauto/src/state/client_controller.dart';
import 'package:appcaixaauto/src/state/theme_controller.dart';
import 'package:appcaixaauto/src/shared/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _VisualRepository repository;
  late ClientController controller;

  setUpAll(() async {
    var flutterCache = File(Platform.resolvedExecutable).parent;
    while (!File(
      '${flutterCache.path}/artifacts/material_fonts/Roboto-Regular.ttf',
    ).existsSync()) {
      final parent = flutterCache.parent;
      if (parent.path == flutterCache.path) {
        throw StateError('Flutter font cache not found.');
      }
      flutterCache = parent;
    }
    final fonts = '${flutterCache.path}/artifacts/material_fonts';
    final regularFont = await File('$fonts/Roboto-Regular.ttf').readAsBytes();
    final boldFont = await File('$fonts/Roboto-Bold.ttf').readAsBytes();
    await (FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(regularFont)))
          ..addFont(Future.value(ByteData.sublistView(boldFont))))
        .load();
    final iconFont = await File(
      '$fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(iconFont)))).load();
    repository = _VisualRepository(await _receiptPng());
  });

  setUp(() {
    controller = ClientController(repository)
      ..session = const AuthSession(token: 'visual-only', user: _user)
      ..data = _bootstrap
      ..phase = LoadPhase.ready;
  });

  testWidgets('gera evidências visuais light', (tester) async {
    await _surface(tester);

    await _capture(
      tester,
      LoginPage(controller: ClientController(repository)),
      'light/login.png',
    );
    await _capture(
      tester,
      RegistrationPage(repository: repository),
      'light/cadastro.png',
    );
    await _capture(
      tester,
      PasswordRecoveryPage(repository: repository),
      'light/recuperacao.png',
    );
    final tenantController = ClientController(repository)
      ..session = const AuthSession(token: 'visual-only', user: _user)
      ..phase = LoadPhase.tenantLinkRequired
      ..initialized = true;
    await _capture(
      tester,
      ClientShell(
        controller: tenantController,
        themeController: ThemeController(),
      ),
      'light/tenant-link.png',
    );
    await _capture(
      tester,
      ClientShell(controller: controller, themeController: ThemeController()),
      'light/home.png',
    );
    await _capture(
      tester,
      CustomerIdentificationPage(
        repository: repository,
        session: controller.session!,
        loyaltyMode: LoyaltyMode.points,
      ),
      'light/meu-qr.png',
    );
    await _capture(
      tester,
      CatalogPage(
        data: _bootstrap,
        repository: repository,
        session: controller.session!,
      ),
      'light/catalogo.png',
    );
    await _capture(
      tester,
      const ProductDetailPage(product: _product, heroTag: 'visual-product'),
      'light/produto.png',
    );
    await _capture(
      tester,
      PurchasesPage(controller: controller, data: _bootstrap),
      'light/compras.png',
    );
    await _capture(
      tester,
      PurchaseDetailPage(purchase: _purchase, controller: controller),
      'light/detalhe-compra.png',
    );
    await _capture(
      tester,
      ReceiptPage(purchaseId: _purchase.id, controller: controller),
      'light/comprovante.png',
    );
    await _capture(
      tester,
      PurchaseDetailPage(purchase: _purchase, controller: controller),
      'light/suporte.png',
      interact: (tester) async {
        await tester.tap(find.text('Preciso de ajuda com esta compra'));
      },
    );
    await _capture(
      tester,
      BenefitsPage(controller: controller, data: _bootstrap),
      'light/beneficios.png',
    );
    await _capture(
      tester,
      BenefitsPage(
        controller: controller,
        data: _bootstrap,
        focus: BenefitsFocus.rewards,
      ),
      'light/recompensas.png',
    );
    await _capture(
      tester,
      BenefitsPage(controller: controller, data: _bootstrap),
      'light/resgate.png',
      interact: (tester) async {
        final action = find.text('Trocar');
        await tester.ensureVisible(action);
        await tester.tap(action);
      },
    );
    await _capture(
      tester,
      BenefitsPage(
        controller: controller,
        data: _bootstrap,
        focus: BenefitsFocus.coupons,
      ),
      'light/cupons.png',
    );
    await _capture(
      tester,
      TemporaryQrPage.coupon(
        repository: repository,
        session: controller.session!,
        coupon: _bootstrap.coupons.first,
      ),
      'light/qr-cupom.png',
    );
    await _capture(
      tester,
      ProfilePage(
        controller: controller,
        data: _bootstrap,
        themeController: ThemeController(),
      ),
      'light/perfil.png',
    );
    await _capture(
      tester,
      ProfilePage(
        controller: controller,
        data: _bootstrap,
        themeController: ThemeController(),
      ),
      'light/aparencia.png',
      interact: (tester) async {
        await tester.tap(find.text('Tema'));
      },
    );
    await _capture(
      tester,
      PreferencesPage(controller: controller),
      'light/preferencias.png',
    );
  });

  testWidgets('gera evidências visuais dark', (tester) async {
    await _surface(tester);
    await _capture(
      tester,
      LoginPage(controller: ClientController(repository)),
      'dark/login.png',
      dark: true,
    );
    await _capture(
      tester,
      ClientShell(controller: controller, themeController: ThemeController()),
      'dark/home.png',
      dark: true,
    );
    await _capture(
      tester,
      BenefitsPage(controller: controller, data: _bootstrap),
      'dark/beneficios.png',
      dark: true,
    );
    await _capture(
      tester,
      ProfilePage(
        controller: controller,
        data: _bootstrap,
        themeController: ThemeController(),
      ),
      'dark/perfil.png',
      dark: true,
    );
  });

  testWidgets('matriz real conecta cadastro e recuperação ao login', (
    tester,
  ) async {
    await _surface(tester);
    await tester.pumpWidget(App247Client(repository: repository));

    await tester.tap(find.byKey(const ValueKey('open-registration')));
    await tester.pumpAndSettle();
    expect(find.byType(RegistrationPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-password-recovery')));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordRecoveryPage), findsOneWidget);
  });

  testWidgets('matriz real conecta home, catálogo e benefícios', (
    tester,
  ) async {
    await _surface(tester);
    await _loginThroughUi(tester, repository);

    await tester.tap(find.byKey(const ValueKey('home-open-catalog')));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogPage), findsOneWidget);
    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-open-rewards')));
    await tester.pumpAndSettle();
    expect(find.byType(BenefitsPage), findsOneWidget);
    expect(find.text('Recompensas'), findsWidgets);
    expect(find.text('Meus cupons'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-open-coupons')));
    await tester.pumpAndSettle();
    expect(find.byType(BenefitsPage), findsOneWidget);
    expect(find.text('Usar no Terminal'), findsOneWidget);
    await tester.tap(find.text('Usar no Terminal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TemporaryQrPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(TemporaryQrPage))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('matriz real conecta compra, comprovante, suporte e perfil', (
    tester,
  ) async {
    await _surface(tester);
    await _loginThroughUi(tester, repository);

    await tester.tap(find.text('Compras').last);
    await tester.pumpAndSettle();
    expect(find.byType(PurchasesPage), findsOneWidget);
    await tester.tap(find.byType(PurchaseCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseDetailPage), findsOneWidget);

    await tester.tap(find.text('Ver comprovante'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preciso de ajuda com esta compra'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar solicitação'), findsOneWidget);
    Navigator.of(tester.element(find.text('Enviar solicitação'))).pop();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-open-preferences')));
    await tester.pumpAndSettle();
    expect(find.byType(PreferencesPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-open-theme')));
    await tester.pumpAndSettle();
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
  });
}

Future<void> _loginThroughUi(
  WidgetTester tester,
  ClientRepository repository,
) async {
  await tester.pumpWidget(App247Client(repository: repository));
  await tester.enterText(find.byType(TextFormField).at(0), '123.456.789-01');
  await tester.enterText(find.byType(TextFormField).at(1), 'segredo8');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
  expect(find.byType(ClientShell), findsOneWidget);
}

Future<void> _surface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
}

Future<void> _capture(
  WidgetTester tester,
  Widget page,
  String file, {
  bool dark = false,
  String? scrollTo,
  Future<void> Function(WidgetTester tester)? interact,
}) async {
  // Desmonta a rota anterior antes de registrar a próxima evidência. Isso
  // evita que frames de transição sobrevivam entre capturas e produzam PNGs
  // parcialmente vazios ou com AppBars sobrepostas.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: _visualTheme(AppTheme.light()),
      darkTheme: _visualTheme(AppTheme.dark()),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: page,
    ),
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 100));
  if (interact != null) {
    await interact(tester);
    await tester.pumpAndSettle();
  }
  final images = tester.widgetList<Image>(find.byType(Image));
  if (images.isNotEmpty) {
    await tester.runAsync(() async {
      for (final image in images) {
        await precacheImage(
          image.image,
          tester.element(find.byType(Image).first),
        );
      }
    });
    await tester.pump();
  }
  if (scrollTo != null) {
    await tester.scrollUntilVisible(
      find.text(scrollTo),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$file'),
  );
}

ThemeData _visualTheme(ThemeData source) {
  final text = source.textTheme.apply(fontFamily: 'Roboto');
  final label = text.labelLarge;
  return source.copyWith(
    textTheme: text,
    appBarTheme: source.appBarTheme.copyWith(titleTextStyle: text.titleLarge),
    filledButtonTheme: FilledButtonThemeData(
      style: (source.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(label),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: (source.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(label),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: (source.elevatedButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(label),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: (source.textButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(label),
      ),
    ),
    chipTheme: source.chipTheme.copyWith(labelStyle: text.labelMedium),
  );
}

const _user = ClientUser(
  id: 'user-visual',
  firstName: 'Jefferson',
  lastName: 'Silva',
  email: 'jefferson@example.com',
  cpf: '52998224725',
  phone: '75999999999',
);

const _product = ProductSummary(
  id: 'p1',
  name: 'Café torrado e moído tradicional 500 g',
  category: 'Mercearia',
  unit: 'Pacote 500 g',
  price: 18.9,
  originalPrice: 22.5,
  description: 'Café encorpado, selecionado para o seu dia a dia.',
  promotionName: 'Oferta da semana',
);

final _purchase = PurchaseSummary(
  id: 'APP247-2026-0913',
  status: PurchaseStatus.approved,
  subtotal: 25.4,
  discount: 1.93,
  total: 23.47,
  createdAt: DateTime(2026, 9, 13, 18, 42),
  paidAt: DateTime(2026, 9, 13, 18, 43),
  condominiumName: 'Residencial Parque das Flores',
  itemCount: 3,
);

final _detail = PurchaseDetail(
  id: _purchase.id,
  status: PurchaseStatus.approved,
  subtotal: 25.4,
  discount: 1.93,
  total: 23.47,
  createdAt: _purchase.createdAt,
  paidAt: _purchase.paidAt,
  items: const [
    PurchaseItem(
      id: 'i1',
      productId: 'p1',
      name: 'Café tradicional 500 g',
      unit: 'pacote',
      quantity: 1,
      originalPrice: 22.5,
      finalPrice: 18.9,
      discount: 1.93,
      subtotal: 18.9,
    ),
    PurchaseItem(
      id: 'i2',
      productId: 'p2',
      name: 'Água mineral sem gás',
      unit: 'garrafa',
      quantity: 1,
      originalPrice: 4.57,
      finalPrice: 4.57,
      discount: 0,
      subtotal: 4.57,
    ),
  ],
);

final _bootstrap = ClientBootstrap(
  user: _user,
  condominium: const CondominiumSummary(
    id: 'cond-visual',
    name: 'Residencial Parque das Flores',
  ),
  capabilities: const ClientCapabilities(
    catalog: true,
    promotions: true,
    identificationQr: true,
    loyalty: true,
    points: true,
    rewards: true,
    coupons: true,
    preferences: true,
    purchaseSupport: true,
  ),
  products: const [
    _product,
    ProductSummary(
      id: 'p2',
      name: 'Água mineral sem gás',
      category: 'Bebidas',
      unit: 'Garrafa 1,5 L',
      price: 4.57,
    ),
    ProductSummary(
      id: 'p3',
      name: 'Chocolate ao leite',
      category: 'Doces',
      unit: 'Barra 90 g',
      price: 7.9,
      originalPrice: 9.9,
    ),
  ],
  purchases: [_purchase],
  loyaltyMode: LoyaltyMode.points,
  loyalty: LoyaltySummary(
    mode: LoyaltyMode.points,
    points: 850,
    nextRewardPoints: 1000,
    couponsAvailable: 1,
    movements: [
      LoyaltyMovement(
        id: 'm1',
        type: 'EARN',
        description: 'Compra no Terminal',
        createdAt: DateTime(2026, 9, 13),
        pointsDelta: 24,
      ),
    ],
  ),
  rewards: [
    RewardSummary(
      id: 'reward-1',
      title: '10% de desconto',
      pointsCost: 500,
      minimumPurchase: 80,
      maximumDiscount: 25,
      validUntil: DateTime(2026, 12, 31),
    ),
  ],
  coupons: [
    CouponSummary(
      id: 'coupon-1',
      title: '10% OFF na próxima compra',
      minimumPurchase: 50,
      maximumDiscount: 20,
      validUntil: DateTime(2026, 12, 31),
      status: CouponStatus.available,
    ),
  ],
);

class _VisualRepository implements ClientRepository, ClientFeatureRepository {
  _VisualRepository(this.receiptBytes);
  final Uint8List receiptBytes;

  @override
  Future<AuthSession> login({
    required String cpf,
    required String password,
  }) async => const AuthSession(token: 'visual-only', user: _user);
  @override
  Future<ClientBootstrap> loadBootstrap(AuthSession session) async =>
      _bootstrap;
  @override
  Future<List<PurchaseSummary>> loadPurchases(AuthSession session) async => [
    _purchase,
  ];
  @override
  Future<void> requestPasswordRecovery(String cpf) async {}
  @override
  Future<String> validatePasswordRecoveryCode(String cpf, String code) async =>
      'visual-reset';
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
  Future<CustomerIdentificationToken> createIdentificationToken(
    AuthSession session,
  ) async {
    final now = DateTime.now();
    return CustomerIdentificationToken(
      qrPayload: 'app247:visual-identification-token',
      expiresAt: now.add(const Duration(minutes: 2)),
      serverTime: now,
    );
  }

  @override
  Future<TemporaryQrToken> createCouponToken(
    AuthSession session,
    String couponId,
  ) async => TemporaryQrToken(
    value: 'app247:visual-coupon-token',
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    serverTime: DateTime.now(),
  );
  @override
  Future<ClientBootstrap> redeemReward(
    AuthSession session,
    String rewardId,
  ) async => _bootstrap;
  @override
  Future<PageResult<ProductSummary>> loadCatalog(
    AuthSession session, {
    String? query,
    String? category,
    int page = 0,
    int size = 20,
  }) async => PageResult(
    content: _bootstrap.products,
    page: 0,
    size: size,
    totalElements: _bootstrap.products.length,
    totalPages: 1,
  );
  @override
  Future<PageResult<PurchaseSummary>> loadPurchasePage(
    AuthSession session, {
    int page = 0,
    int size = 20,
  }) async => PageResult(
    content: [_purchase],
    page: 0,
    size: size,
    totalElements: 1,
    totalPages: 1,
  );
  @override
  Future<PurchaseDetail> loadPurchase(
    AuthSession session,
    String purchaseId,
  ) async => _detail;
  @override
  Future<ReceiptImage> loadReceipt(
    AuthSession session,
    String purchaseId,
  ) async => ReceiptImage(bytes: receiptBytes);
  @override
  Future<void> sendReceipt(
    AuthSession session,
    String purchaseId, {
    required String channel,
    required String recipient,
  }) async {}
  @override
  Future<SupportResult> requestPurchaseSupport(
    AuthSession session,
    String purchaseId, {
    required String category,
    required String message,
  }) async => const SupportResult(protocol: 'SUP-247-001', status: 'OPEN');
  @override
  Future<LoyaltySummary> loadLoyalty(AuthSession session) async =>
      _bootstrap.loyalty!;
  @override
  Future<List<RewardSummary>> loadRewards(AuthSession session) async =>
      _bootstrap.rewards;
  @override
  Future<RedemptionResult> redeemRewardWithKey(
    AuthSession session,
    String rewardId,
    String idempotencyKey,
  ) async => const RedemptionResult(
    id: 'redemption-1',
    couponId: 'coupon-1',
    status: 'CREATED',
  );
  @override
  Future<List<CouponSummary>> loadCoupons(AuthSession session) async =>
      _bootstrap.coupons;
  @override
  Future<PreferenceSettings> loadPreferences(AuthSession session) async =>
      const PreferenceSettings(autoEmail: true, autoWhatsapp: false);
  @override
  Future<PreferenceSettings> updatePreferences(
    AuthSession session,
    PreferenceSettings preferences,
  ) async => preferences;
}

Future<Uint8List> _receiptPng() async {
  const width = 700;
  const height = 980;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
  final navy = Paint()..color = AppColors.navy;
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), 150), navy);
  void label(
    String text,
    double x,
    double y,
    double size, {
    Color color = AppColors.navy,
    FontWeight weight = FontWeight.w400,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          color: color,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 80);
    painter.paint(canvas, Offset(x, y));
  }

  label('APP 24/7', 40, 42, 42, color: Colors.white, weight: FontWeight.w700);
  label('COMPROVANTE DE COMPRA', 40, 190, 28, weight: FontWeight.w700);
  label('Residencial Parque das Flores', 40, 245, 23);
  label('13/09/2026  •  18:42', 40, 285, 20);
  label('Café tradicional 500 g                 R\$ 18,90', 40, 370, 19);
  label('Água mineral sem gás                     R\$ 4,57', 40, 420, 19);
  canvas.drawLine(
    const Offset(40, 490),
    const Offset(660, 490),
    navy..strokeWidth = 2,
  );
  label(
    'DESCONTOS                                      - R\$ 1,93',
    40,
    535,
    20,
  );
  label(
    'TOTAL                                             R\$ 23,47',
    40,
    605,
    28,
    weight: FontWeight.w700,
  );
  label(
    'Pagamento aprovado',
    40,
    700,
    22,
    color: AppColors.fresh,
    weight: FontWeight.w700,
  );
  label('Compra #APP247-2026-0913', 40, 755, 19);
  label('Obrigado por comprar com o App247.', 40, 865, 20);
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
