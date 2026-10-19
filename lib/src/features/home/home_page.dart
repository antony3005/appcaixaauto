import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
import '../../state/theme_controller.dart';
import '../benefits/benefits_page.dart';
import '../catalog/catalog_pages.dart';
import '../purchases/purchases_page.dart';
import '../qr/customer_identification_page.dart';
import '../shell/client_shell.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.controller,
    required this.data,
    super.key,
    this.themeController,
  });

  final ClientController controller;
  final ClientBootstrap data;
  final ThemeController? themeController;

  @override
  Widget build(BuildContext context) {
    final loyaltyMode = _resolveLoyaltyMode(data);
    final offers = data.capabilities.promotions
        ? data.products.where((product) => product.isPromotion).toList()
        : const <ProductSummary>[];
    final products = offers.isNotEmpty ? offers : data.products;
    final showLoyalty =
        data.capabilities.loyalty &&
        data.loyalty != null &&
        loyaltyMode != LoyaltyMode.none;
    final showQr = data.capabilities.identificationQr;
    final showRewards = data.capabilities.benefits && data.capabilities.rewards;
    final showCoupons = data.capabilities.benefits && data.capabilities.coupons;
    final availableCoupons = data.coupons
        .where((coupon) => coupon.status == CouponStatus.available)
        .length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            children: [
              AppContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.s4),
                    _Greeting(
                      data: data,
                      now: controller.clock(),
                      onProfile: () => _openProfile(context),
                    ),
                    if (showLoyalty || showQr) ...[
                      const SizedBox(height: AppSpacing.s5),
                      _HeroPair(
                        loyalty: showLoyalty
                            ? PointsCard(
                                key: const ValueKey('home-open-benefits'),
                                label: loyaltyMode == LoyaltyMode.points
                                    ? 'Meus pontos'
                                    : 'Meu cashback',
                                value: loyaltyMode == LoyaltyMode.points
                                    ? points(data.loyalty?.points ?? 0)
                                    : money(data.loyalty?.cashback ?? 0),
                                unit: loyaltyMode == LoyaltyMode.points
                                    ? 'pts'
                                    : null,
                                caption: _loyaltyCaption(
                                  data.loyalty!,
                                  loyaltyMode,
                                ),
                                onTap: data.capabilities.benefits
                                    ? () => _openBenefits(
                                        context,
                                        BenefitsFocus.overview,
                                      )
                                    : null,
                              )
                            : null,
                        qr: showQr
                            ? QrTile(
                                key: const ValueKey(
                                  'open-customer-identification',
                                ),
                                onTap: () => _openQr(context),
                              )
                            : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s4),
                    const Notice(message: terminalReminder),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.s3),
                      Notice(
                        tone: NoticeTone.warning,
                        icon: Icons.info_outline_rounded,
                        message: controller.errorMessage!,
                        live: true,
                      ),
                    ],
                    if (showRewards || showCoupons) ...[
                      const SizedBox(height: AppSpacing.section),
                      const SectionHeader(title: 'Benefícios'),
                      ListGroup(
                        children: [
                          if (showRewards)
                            AppListRow(
                              key: const ValueKey('home-open-rewards'),
                              leading: const IconWell(
                                icon: Icons.redeem_rounded,
                                tone: WellTone.gold,
                              ),
                              title: 'Recompensas',
                              subtitle: data.rewards.isEmpty
                                  ? 'Nenhuma disponível agora'
                                  : 'Troque seus pontos por descontos',
                              onTap: () =>
                                  _openBenefits(context, BenefitsFocus.rewards),
                            ),
                          if (showCoupons)
                            AppListRow(
                              key: const ValueKey('home-open-coupons'),
                              leading: const IconWell(
                                icon: Icons.confirmation_number_outlined,
                              ),
                              title: 'Meus cupons',
                              subtitle: availableCoupons == 0
                                  ? 'Nenhum cupom para usar'
                                  : '$availableCoupons ${availableCoupons == 1 ? 'disponível' : 'disponíveis'} no Terminal',
                              onTap: () =>
                                  _openBenefits(context, BenefitsFocus.coupons),
                            ),
                        ],
                      ),
                    ],
                    if (data.capabilities.catalog && products.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.section),
                      SectionHeader(
                        title: offers.isNotEmpty
                            ? 'Promoções de hoje'
                            : 'No seu mercado',
                        trailing: TextButton(
                          key: const ValueKey('home-open-catalog'),
                          onPressed: () =>
                              selectShellTab(controller, ShellTab.catalog),
                          child: const Text('Ver catálogo'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                    ],
                  ],
                ),
              ),
              if (data.capabilities.catalog && products.isNotEmpty)
                _ProductStrip(
                  products: products.take(6).toList(),
                  onOpen: (product, heroTag) =>
                      _openProduct(context, product, heroTag),
                ),
              AppContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.section),
                    SectionHeader(
                      title: 'Compras recentes',
                      actionLabel: data.purchases.isEmpty ? null : 'Ver todas',
                      onAction: () =>
                          selectShellTab(controller, ShellTab.purchases),
                    ),
                    if (data.purchases.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Seu histórico começa aqui',
                        message:
                            'Identifique-se no Terminal para salvar suas próximas compras.',
                      )
                    else
                      PurchaseList(
                        purchases: data.purchases.take(2).toList(),
                        onOpen: (purchase) =>
                            openPurchaseDetail(context, purchase, controller),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LoyaltyMode _resolveLoyaltyMode(ClientBootstrap bootstrap) {
    final summaryMode = bootstrap.loyalty?.mode ?? LoyaltyMode.none;
    if (summaryMode != LoyaltyMode.none) return summaryMode;
    if (bootstrap.loyaltyMode != LoyaltyMode.none) {
      return bootstrap.loyaltyMode;
    }
    if (bootstrap.capabilities.points) return LoyaltyMode.points;
    if (bootstrap.capabilities.cashback) return LoyaltyMode.cashback;
    return LoyaltyMode.none;
  }

  String _loyaltyCaption(LoyaltySummary summary, LoyaltyMode mode) {
    if (mode == LoyaltyMode.points &&
        summary.cashback != null &&
        summary.cashback! > 0) {
      return '${money(summary.cashback!)} em cashback';
    }
    if (summary.nextReward != null) {
      return 'Próxima: ${summary.nextReward!.title}';
    }
    return 'Saldo disponível';
  }

  void _openQr(BuildContext context) {
    if (shellTabs(data).contains(ShellTab.qr)) {
      selectShellTab(controller, ShellTab.qr);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerIdentificationPage(
          repository: controller.repository,
          session: controller.session!,
          loyaltyMode: data.loyaltyMode,
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) =>
      selectShellTab(controller, ShellTab.profile);

  void _openBenefits(BuildContext context, BenefitsFocus focus) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BenefitsPage(controller: controller, data: data, focus: focus),
        ),
      );

  void _openProduct(
    BuildContext context,
    ProductSummary product,
    String heroTag,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailPage(product: product, heroTag: heroTag),
    ),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.data,
    required this.now,
    required this.onProfile,
  });
  final ClientBootstrap data;
  final DateTime now;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final name = data.user.firstName.isEmpty ? 'cliente' : data.user.firstName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_greeting(now)}, $name', style: context.text.bodySmall),
              const SizedBox(height: 2),
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.apartment_rounded,
                      size: AppSizes.iconMd,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      data.condominium?.name ?? 'Condomínio não informado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Semantics(
          button: true,
          label: 'Abrir perfil de ${data.user.fullName}',
          excludeSemantics: true,
          child: Material(
            key: const ValueKey('home-open-profile'),
            color: AppColors.navy,
            shape: CircleBorder(
              side: context.isDark
                  ? BorderSide(color: context.colors.outline)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onProfile,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: Text(
                    data.user.firstName.isEmpty
                        ? '24'
                        : data.user.firstName.characters.first.toUpperCase(),
                    style: context.text.titleMedium?.copyWith(
                      color: AppColors.onNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Par de destaque: saldo dourado ao lado do tile navy do Meu QR.
class _HeroPair extends StatelessWidget {
  const _HeroPair({required this.loyalty, required this.qr});
  final Widget? loyalty, qr;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.6;
    if (loyalty == null || qr == null || stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?loyalty,
          if (loyalty != null && qr != null)
            const SizedBox(height: AppSpacing.s3),
          ?qr,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 16, child: loyalty!),
          const SizedBox(width: AppSpacing.s3),
          Expanded(flex: 10, child: qr!),
        ],
      ),
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip({required this.products, required this.onOpen});
  final List<ProductSummary> products;
  final void Function(ProductSummary product, String heroTag) onOpen;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 252 * scale,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMax),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter - AppSpacing.s1,
            ),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2),
            itemBuilder: (context, index) {
              final product = products[index];
              final heroTag = 'home-product-${product.id}-$index';
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: product,
                  heroTag: heroTag,
                  onTap: () => onOpen(product, heroTag),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _greeting(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
