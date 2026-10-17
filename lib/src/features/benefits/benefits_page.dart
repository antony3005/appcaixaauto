import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
import '../qr/temporary_qr_page.dart';

enum BenefitsFocus { overview, rewards, coupons }

class BenefitsPage extends StatelessWidget {
  const BenefitsPage({
    required this.controller,
    required this.data,
    super.key,
    this.focus = BenefitsFocus.overview,
  });
  final ClientController controller;
  final ClientBootstrap data;
  final BenefitsFocus focus;

  bool get showOverview => focus == BenefitsFocus.overview;
  bool get showRewards => focus != BenefitsFocus.coupons;
  bool get showCoupons => focus != BenefitsFocus.rewards;

  String get title => switch (focus) {
    BenefitsFocus.overview => 'Benefícios',
    BenefitsFocus.rewards => 'Recompensas',
    BenefitsFocus.coupons => 'Meus cupons',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: AppContent(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            if (showOverview && data.loyalty != null)
              _BalanceHero(
                summary: data.loyalty!,
                capabilities: data.capabilities,
              ),
            if (showOverview && data.loyalty?.movements.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Movimentações'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: data.loyalty!.movements
                      .map(
                        (movement) => _MovementRow(
                          movement: movement,
                          mode: data.loyalty!.mode,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (showRewards && data.capabilities.rewards) ...[
              SizedBox(height: showOverview ? AppSpacing.lg : AppSpacing.xs),
              if (showOverview) const SectionHeader(title: 'Recompensas'),
              const SizedBox(height: AppSpacing.sm),
              if (data.rewards.isEmpty)
                const EmptyState(
                  icon: Icons.redeem_outlined,
                  title: 'Nenhuma recompensa disponível',
                  message:
                      'Novas opções aparecerão aqui quando estiverem disponíveis.',
                )
              else
                ...data.rewards.map(
                  (reward) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _RewardCard(
                      reward: reward,
                      busy: controller.redeemingRewardId == reward.id,
                      onRedeem: () => _confirmReward(context, reward),
                    ),
                  ),
                ),
            ],
            if (showCoupons && data.capabilities.coupons) ...[
              SizedBox(height: showOverview ? AppSpacing.lg : AppSpacing.xs),
              if (showOverview) const SectionHeader(title: 'Meus cupons'),
              const SizedBox(height: AppSpacing.sm),
              if (data.coupons.isEmpty)
                const EmptyState(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Nenhum cupom disponível',
                  message: 'Você ainda não possui cupons disponíveis.',
                )
              else
                ..._couponGroups(data.coupons).entries.expand(
                  (group) => [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        group.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...group.value.map(
                      (coupon) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _CouponCard(
                          coupon: coupon,
                          onUse: coupon.status == CouponStatus.available
                              ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TemporaryQrPage.coupon(
                                      repository: controller.repository,
                                      session: controller.session!,
                                      coupon: coupon,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmReward(
    BuildContext context,
    RewardSummary reward,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trocar ${reward.pointsCost} pontos por ${reward.title}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compra mínima: ${money(reward.minimumPurchase)}'),
            if (reward.maximumDiscount != null)
              Text('Desconto máximo: ${money(reward.maximumDiscount!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await controller.redeemReward(reward.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Recompensa resgatada. Seu cupom já está disponível.'
              : controller.errorMessage ?? 'Não foi possível resgatar.',
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary, required this.capabilities});
  final LoyaltySummary summary;
  final ClientCapabilities capabilities;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(AppRadii.hero),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.stars_rounded, color: context.semantic.gold, size: 36),
        const SizedBox(height: AppSpacing.md),
        Text(
          summary.mode == LoyaltyMode.points ? 'Meus pontos' : 'Meu cashback',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.darkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          summary.mode == LoyaltyMode.points
              ? '${summary.points ?? 0} pts'
              : money(summary.cashback ?? 0),
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: AppColors.darkText),
        ),
        if (summary.mode == LoyaltyMode.points &&
            summary.nextReward != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Próxima recompensa: ${summary.nextReward!.pointsCost} pts',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.darkText),
          ),
        ],
      ],
    ),
  );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.busy,
    required this.onRedeem,
  });
  final RewardSummary reward;
  final bool busy;
  final VoidCallback onRedeem;
  @override
  Widget build(BuildContext context) => AppCard(
    variant: AppCardVariant.premium,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.semantic.gold.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.redeem_rounded, color: context.semantic.gold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                reward.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.semantic.gold.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            '${reward.pointsCost} pontos',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: context.semantic.onGold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Em compras acima de ${money(reward.minimumPurchase)}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (reward.maximumDiscount != null)
          Text(
            'Desconto máximo: ${money(reward.maximumDiscount!)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
          ),
        if (reward.validUntil != null)
          Text(
            'Válida até ${localDate(reward.validUntil!)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
          ),
        if (!reward.available && reward.unavailableReason?.isNotEmpty == true)
          Text(
            reward.unavailableReason!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: reward.available && !busy ? onRedeem : null,
            icon: const Icon(Icons.redeem_rounded),
            label: Text(
              busy
                  ? 'Resgatando...'
                  : reward.available
                  ? 'Trocar'
                  : 'Indisponível',
            ),
          ),
        ),
      ],
    ),
  );
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.onUse});
  final CouponSummary coupon;
  final VoidCallback? onUse;
  @override
  Widget build(BuildContext context) {
    final label = switch (coupon.status) {
      CouponStatus.available => 'Disponível',
      CouponStatus.reserved => 'Reservado',
      CouponStatus.used => 'Usado',
      CouponStatus.expired => 'Expirado',
      CouponStatus.cancelled => 'Cancelado',
      CouponStatus.unknown => 'Em atualização',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: coupon.status == CouponStatus.available
                        ? AppColors.fresh
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Compra mínima: ${money(coupon.minimumPurchase)}'),
            if (coupon.maximumDiscount != null)
              Text('Desconto máximo: ${money(coupon.maximumDiscount!)}'),
            Text(
              'Válido até ${localDate(coupon.validUntil)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            if (onUse != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUse,
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Usar no Terminal'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.mode});
  final LoyaltyMovement movement;
  final LoyaltyMode mode;

  @override
  Widget build(BuildContext context) {
    final points = movement.pointsDelta ?? 0;
    final cashback = movement.cashbackDelta ?? 0;
    final positive = mode == LoyaltyMode.points ? points >= 0 : cashback >= 0;
    final amount = mode == LoyaltyMode.points
        ? '${points >= 0 ? '+' : ''}$points pts'
        : '${cashback >= 0 ? '+' : '-'} ${money(cashback.abs())}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positive
                  ? context.semantic.successContainer
                  : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              color: positive
                  ? context.semantic.success
                  : context.semantic.muted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description.isEmpty
                      ? movement.type
                      : movement.description,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  localDate(movement.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semantic.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: positive
                  ? context.semantic.success
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<CouponSummary>> _couponGroups(List<CouponSummary> coupons) {
  final available = coupons
      .where(
        (coupon) =>
            coupon.status == CouponStatus.available ||
            coupon.status == CouponStatus.reserved,
      )
      .toList();
  final used = coupons
      .where((coupon) => coupon.status == CouponStatus.used)
      .toList();
  final expired = coupons
      .where(
        (coupon) =>
            coupon.status == CouponStatus.expired ||
            coupon.status == CouponStatus.cancelled ||
            coupon.status == CouponStatus.unknown,
      )
      .toList();
  return {
    if (available.isNotEmpty) 'Disponíveis': available,
    if (used.isNotEmpty) 'Usados': used,
    if (expired.isNotEmpty) 'Expirados e cancelados': expired,
  };
}
