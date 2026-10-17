import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
import '../benefits/benefits_page.dart';
import '../catalog/catalog_pages.dart';
import '../purchases/purchases_page.dart';
import '../qr/customer_identification_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, required this.data, super.key});

  final ClientController controller;
  final ClientBootstrap data;

  @override
  Widget build(BuildContext context) {
    final loyaltyMode = _resolveLoyaltyMode(data);
    final offers = data.products
        .where((product) => product.isPromotion)
        .toList();
    final products = offers.isNotEmpty ? offers : data.products;
    final showLoyalty =
        data.capabilities.loyalty &&
        data.loyalty != null &&
        loyaltyMode != LoyaltyMode.none;
    final showQr = data.capabilities.identificationQr;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _HomeHero(
                data: data,
                showLoyalty: showLoyalty,
                loyaltyMode: loyaltyMode,
                showQr: showQr,
                onLoyaltyTap: data.capabilities.benefits
                    ? () => controller.selectNavigation(2)
                    : null,
                onQrTap: () => _openQr(context),
              ),
              if (controller.errorMessage != null)
                AppContent(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.md,
                    ),
                    child: _InlineWarning(message: controller.errorMessage!),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              const AppContent(child: SectionHeader(title: 'Acesso rápido')),
              AppContent(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xl,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - AppSpacing.sm) / 2;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _ShortcutTile(
                            key: const ValueKey('home-open-purchases'),
                            width: width,
                            icon: Icons.receipt_long_rounded,
                            label: 'Compras',
                            helper: 'Seu histórico',
                            onTap: () => controller.selectNavigation(1),
                          ),
                          if (data.capabilities.catalog)
                            _ShortcutTile(
                              key: const ValueKey('home-open-catalog'),
                              width: width,
                              icon: Icons.grid_view_rounded,
                              label: 'Catálogo',
                              helper: 'Produtos e preços',
                              onTap: () => _openCatalog(context),
                            ),
                          if (data.capabilities.coupons)
                            _ShortcutTile(
                              key: const ValueKey('home-open-coupons'),
                              width: width,
                              icon: Icons.confirmation_number_rounded,
                              label: 'Cupons',
                              helper: 'Disponíveis para usar',
                              premium: true,
                              onTap: () =>
                                  _openBenefits(context, BenefitsFocus.coupons),
                            ),
                          if (data.capabilities.rewards)
                            _ShortcutTile(
                              key: const ValueKey('home-open-rewards'),
                              width: width,
                              icon: Icons.redeem_rounded,
                              label: 'Recompensas',
                              helper: 'Troque seus pontos',
                              premium: true,
                              onTap: () =>
                                  _openBenefits(context, BenefitsFocus.rewards),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (data.capabilities.catalog && products.isNotEmpty) ...[
                AppContent(
                  child: SectionHeader(
                    title: offers.isNotEmpty
                        ? 'Ofertas para você'
                        : 'No seu mercado',
                    actionLabel: 'Ver catálogo',
                    onAction: () => _openCatalog(context),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.textScalerOf(
                    context,
                  ).scale(250).clamp(286, 336),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    itemCount: products.take(6).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final heroTag = 'home-product-${product.id}-$index';
                      return SizedBox(
                        width: 164,
                        child: ProductCard(
                          product: product,
                          heroTag: heroTag,
                          onTap: () => _openProduct(context, product, heroTag),
                        ),
                      );
                    },
                  ),
                ),
              ],
              AppContent(
                child: SectionHeader(
                  title: 'Compras recentes',
                  actionLabel: data.purchases.isEmpty ? null : 'Ver todas',
                  onAction: () => controller.selectNavigation(1),
                ),
              ),
              if (data.purchases.isEmpty)
                const AppContent(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Seu histórico começa aqui',
                    message:
                        'Identifique-se no Terminal para salvar suas próximas compras.',
                  ),
                )
              else
                AppContent(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < data.purchases.take(2).length;
                          index++
                        ) ...[
                          PurchaseCard(
                            purchase: data.purchases[index],
                            onTap: () => openPurchaseDetail(
                              context,
                              data.purchases[index],
                              controller,
                            ),
                          ),
                          if (index + 1 < data.purchases.take(2).length)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
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

  void _openQr(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CustomerIdentificationPage(
        repository: controller.repository,
        session: controller.session!,
        loyaltyMode: data.loyaltyMode,
      ),
    ),
  );

  void _openCatalog(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CatalogPage(
        data: data,
        repository: controller.repository,
        session: controller.session!,
      ),
    ),
  );

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

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.data,
    required this.showLoyalty,
    required this.loyaltyMode,
    required this.showQr,
    required this.onLoyaltyTap,
    required this.onQrTap,
  });

  final ClientBootstrap data;
  final bool showLoyalty;
  final LoyaltyMode loyaltyMode;
  final bool showQr;
  final VoidCallback? onLoyaltyTap;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    final onNavy = AppColors.darkText;
    final mutedOnNavy = AppColors.darkMuted;
    return Material(
      color: AppColors.navy,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.hero + AppSpacing.xs),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, ${data.user.firstName.isEmpty ? 'cliente' : data.user.firstName}',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(color: onNavy),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkText.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 17,
                                color: context.semantic.gold,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  data.condominium?.name ??
                                      'Condomínio não informado',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: mutedOnNavy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Semantics(
                    label: 'Perfil de ${data.user.fullName}',
                    image: true,
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.darkText.withValues(alpha: .12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkText.withValues(alpha: .18),
                        ),
                      ),
                      child: Text(
                        data.user.firstName.isEmpty
                            ? '24'
                            : data.user.firstName.characters.first
                                  .toUpperCase(),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: onNavy),
                      ),
                    ),
                  ),
                ],
              ),
              if (showLoyalty || showQr) ...[
                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showLoyalty)
                        Expanded(
                          flex: 5,
                          child: _HeroAction(
                            onTap: onLoyaltyTap,
                            icon: Icons.stars_rounded,
                            eyebrow: loyaltyMode == LoyaltyMode.points
                                ? 'FIDELIDADE'
                                : 'CASHBACK',
                            title: loyaltyMode == LoyaltyMode.points
                                ? '${data.loyalty?.points ?? 0} pts'
                                : money(data.loyalty?.cashback ?? 0),
                            caption: data.loyalty?.nextReward == null
                                ? 'Saldo disponível'
                                : 'Próxima: ${data.loyalty!.nextReward!.title}',
                            premium: true,
                          ),
                        ),
                      if (showLoyalty && showQr)
                        const SizedBox(width: AppSpacing.sm),
                      if (showQr)
                        Expanded(
                          flex: showLoyalty ? 4 : 1,
                          child: _HeroAction(
                            key: const ValueKey('open-customer-identification'),
                            onTap: onQrTap,
                            icon: Icons.qr_code_2_rounded,
                            eyebrow: 'IDENTIFICAÇÃO',
                            title: 'Meu QR',
                            caption: 'Usar no Terminal',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.onTap,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.caption,
    super.key,
    this.premium = false,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String eyebrow, title, caption;
  final bool premium;

  @override
  Widget build(BuildContext context) => Material(
    color: premium
        ? context.semantic.goldContainer
        : AppColors.darkText.withValues(alpha: .10),
    borderRadius: BorderRadius.circular(AppRadii.card),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 154),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: premium ? context.semantic.gold : AppColors.darkText,
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: premium
                          ? context.semantic.onGold
                          : AppColors.darkMuted,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: premium
                      ? context.semantic.onGold.withValues(alpha: .72)
                      : AppColors.darkMuted,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: premium ? context.semantic.onGold : AppColors.darkText,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: premium
                      ? context.semantic.onGold.withValues(alpha: .72)
                      : AppColors.darkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.helper,
    required this.onTap,
    super.key,
    this.premium = false,
  });

  final double width;
  final IconData icon;
  final String label, helper;
  final VoidCallback onTap;
  final bool premium;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: premium
          ? context.semantic.goldContainer
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(
          color: premium
              ? context.semantic.gold.withValues(alpha: .22)
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: premium
                          ? context.semantic.gold.withValues(alpha: .12)
                          : Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 21,
                      color: premium
                          ? context.semantic.gold
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: context.semantic.muted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.semantic.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: context.semantic.warningContainer,
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: context.semantic.warning),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
