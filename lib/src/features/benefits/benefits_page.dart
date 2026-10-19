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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _build(context, controller.data ?? data),
  );

  Widget _build(BuildContext context, ClientBootstrap data) {
    final loyalty = data.loyalty;
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          children: [
            AppContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showOverview && loyalty != null) ...[
                    const SizedBox(height: AppSpacing.s2),
                    PointsCard(
                      label: loyalty.mode == LoyaltyMode.cashback
                          ? 'Meu cashback'
                          : 'Meus pontos',
                      value: loyalty.mode == LoyaltyMode.cashback
                          ? money(loyalty.cashback ?? 0)
                          : points(loyalty.points ?? 0),
                      unit: loyalty.mode == LoyaltyMode.cashback ? null : 'pts',
                      caption: loyalty.nextReward != null
                          ? 'Próxima recompensa: ${points(loyalty.nextReward!.pointsCost)} pts'
                          : 'Troque por descontos no Terminal',
                    ),
                  ],
                  if (showOverview &&
                      loyalty?.movements.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.section),
                    const SectionHeader(title: 'Movimentações'),
                    ListGroup(
                      children: [
                        for (final movement in loyalty!.movements)
                          _MovementRow(movement: movement, mode: loyalty.mode),
                      ],
                    ),
                  ],
                  if (showRewards && data.capabilities.rewards) ...[
                    SizedBox(
                      height: showOverview ? AppSpacing.section : AppSpacing.s2,
                    ),
                    if (showOverview) const SectionHeader(title: 'Recompensas'),
                    if (data.rewards.isEmpty)
                      const EmptyState(
                        icon: Icons.redeem_outlined,
                        title: 'Nenhuma recompensa disponível',
                        message:
                            'Novas opções aparecerão aqui quando estiverem disponíveis.',
                      )
                    else
                      ListGroup(
                        children: [
                          for (final reward in data.rewards)
                            _RewardRow(
                              reward: reward,
                              busy: controller.redeemingRewardId == reward.id,
                              onRedeem: () => _confirmReward(context, reward),
                            ),
                        ],
                      ),
                  ],
                  if (showCoupons && data.capabilities.coupons) ...[
                    SizedBox(
                      height: showOverview ? AppSpacing.section : AppSpacing.s2,
                    ),
                    if (showOverview) const SectionHeader(title: 'Meus cupons'),
                    if (data.coupons.isEmpty)
                      const EmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Nenhum cupom disponível',
                        message: 'Você ainda não possui cupons disponíveis.',
                      )
                    else
                      for (final group in _couponGroups(
                        data.coupons,
                      ).entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.s3,
                            bottom: AppSpacing.s1,
                          ),
                          child: Text(
                            group.key.toUpperCase(),
                            style: context.eyebrowStyle.copyWith(
                              color: context.semantic.muted,
                            ),
                          ),
                        ),
                        ListGroup(
                          children: [
                            for (final coupon in group.value)
                              _CouponRow(
                                coupon: coupon,
                                onUse: coupon.status == CouponStatus.available
                                    ? () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              TemporaryQrPage.coupon(
                                                repository:
                                                    controller.repository,
                                                session: controller.session!,
                                                coupon: coupon,
                                              ),
                                        ),
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReward(
    BuildContext context,
    RewardSummary reward,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Center(
          child: IconWell(icon: Icons.redeem_rounded, tone: WellTone.gold),
        ),
        title: Text(
          'Trocar ${points(reward.pointsCost)} pontos por ${reward.title}?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compra mínima: ${money(reward.minimumPurchase)}'),
            if (reward.maximumDiscount != null)
              Text('Desconto máximo: ${money(reward.maximumDiscount!)}'),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'O cupom fica disponível para usar no Terminal.',
              style: context.text.bodySmall,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.s6,
          0,
          AppSpacing.s6,
          AppSpacing.s6,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'CANCELAR',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: PrimaryButton(
                  label: 'TROCAR',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
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

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.reward,
    required this.busy,
    required this.onRedeem,
  });
  final RewardSummary reward;
  final bool busy;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final conditions = [
      'Em compras acima de ${money(reward.minimumPurchase)}',
      if (reward.maximumDiscount != null)
        'máx. ${money(reward.maximumDiscount!)}',
      if (reward.validUntil != null) 'até ${localDate(reward.validUntil!)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconWell(icon: Icons.redeem_rounded, tone: WellTone.gold),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(conditions, style: context.text.bodySmall),
                if (!reward.available &&
                    reward.unavailableReason?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    reward.unavailableReason!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s3,
                  runSpacing: AppSpacing.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppTag(label: '${points(reward.pointsCost)} pontos'),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: reward.available && !busy ? onRedeem : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s4,
                          ),
                        ),
                        child: busy
                            ? DotsLoader(color: context.colors.onPrimary)
                            : Text(
                                reward.available ? 'TROCAR' : 'INDISPONÍVEL',
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  const _CouponRow({required this.coupon, required this.onUse});
  final CouponSummary coupon;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (coupon.status) {
      CouponStatus.available => ('Disponível', StatusTone.success),
      CouponStatus.reserved => ('Reservado', StatusTone.warning),
      CouponStatus.used => ('Usado', StatusTone.neutral),
      CouponStatus.expired => ('Expirado', StatusTone.error),
      CouponStatus.cancelled => ('Cancelado', StatusTone.error),
      CouponStatus.unknown => ('Em atualização', StatusTone.neutral),
    };
    final details = [
      'Compra mínima: ${money(coupon.minimumPurchase)}',
      if (coupon.maximumDiscount != null)
        'máx. ${money(coupon.maximumDiscount!)}',
      'válido até ${localDate(coupon.validUntil)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconWell(
            icon: Icons.confirmation_number_outlined,
            tone: onUse != null ? WellTone.primary : WellTone.neutral,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coupon.title, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(details, style: context.text.bodySmall),
                const SizedBox(height: AppSpacing.s2),
                Wrap(
                  spacing: AppSpacing.s3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusDot(label: label, tone: tone),
                    if (onUse != null)
                      TextButton.icon(
                        onPressed: onUse,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s1,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('Usar no Terminal'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    final pointsDelta = movement.pointsDelta ?? 0;
    final cashback = movement.cashbackDelta ?? 0;
    final positive = mode == LoyaltyMode.cashback
        ? cashback >= 0
        : pointsDelta >= 0;
    final amount = mode == LoyaltyMode.cashback
        ? '${cashback >= 0 ? '+' : '−'} ${money(cashback.abs())}'
        : '${pointsDelta >= 0 ? '+' : '−'}${points(pointsDelta.abs())} pts';
    return AppListRow(
      leading: IconWell(
        icon: positive ? Icons.add_rounded : Icons.remove_rounded,
        tone: positive ? WellTone.success : WellTone.neutral,
      ),
      title: movement.description.isEmpty
          ? movement.type
          : movement.description,
      subtitle: localDate(movement.createdAt),
      trailing: Text(
        amount,
        style: context.text.titleSmall?.copyWith(
          color: positive ? context.semantic.success : context.colors.onSurface,
        ),
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
