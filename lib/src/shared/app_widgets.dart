import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../domain/models.dart';

final _currency = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
final _date = DateFormat('dd/MM/yyyy');
final _time = DateFormat('HH:mm');

String money(double value) => _currency.format(value);
String localDate(DateTime value) => _date.format(value.toLocal());
String localTime(DateTime value) => _time.format(value.toLocal());

class AppContent extends StatelessWidget {
  const AppContent({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ?trailing,
    ],
  );
}

enum AppCardVariant { standard, highlight, interactive, premium }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding,
    this.variant = AppCardVariant.standard,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets? padding;
  final AppCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (variant) {
      AppCardVariant.standard => scheme.surface,
      AppCardVariant.highlight => scheme.primaryContainer,
      AppCardVariant.interactive => scheme.surfaceContainerLow,
      AppCardVariant.premium => context.semantic.goldContainer,
    };
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: variant == AppCardVariant.standard
            ? BorderSide(color: scheme.outline)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
          ),
        ],
      ),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.coral),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

class LoadingSection extends StatelessWidget {
  const LoadingSection({super.key, this.rows = 3});
  final int rows;
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      rows,
      (index) => Container(
        height: 88,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: index.isEven
              ? Theme.of(context).colorScheme.surfaceContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    ),
  );
}

class LoadingTile extends StatelessWidget {
  const LoadingTile({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .55, end: 1),
    duration: AppAnimations.long,
    curve: AppAnimations.standard,
    builder: (context, opacity, _) => Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainer.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});
  final PurchaseStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, icon, background, foreground) = switch (status) {
      PurchaseStatus.approved => (
        'Aprovada',
        Icons.check_circle_outline,
        AppColors.successSoft,
        AppColors.fresh,
      ),
      PurchaseStatus.canceled => (
        'Cancelada',
        Icons.cancel_outlined,
        AppColors.errorSoft,
        AppColors.coral,
      ),
      PurchaseStatus.failed => (
        'Não aprovada',
        Icons.error_outline,
        AppColors.errorSoft,
        AppColors.coral,
      ),
      PurchaseStatus.expired => (
        'Expirada',
        Icons.timer_off_outlined,
        AppColors.warningSoft,
        const Color(0xFF855600),
      ),
      PurchaseStatus.refunded => (
        'Reembolsada',
        Icons.replay,
        const Color(0xFFE8EFF5),
        AppColors.navy,
      ),
      PurchaseStatus.actionRequired => (
        'Ação necessária',
        Icons.info_outline,
        AppColors.warningSoft,
        const Color(0xFF855600),
      ),
      PurchaseStatus.pending ||
      PurchaseStatus.created ||
      PurchaseStatus.atTerminal => (
        'Aguardando confirmação',
        Icons.schedule,
        AppColors.warningSoft,
        const Color(0xFF855600),
      ),
      PurchaseStatus.unknown => (
        'Em atualização',
        Icons.sync,
        const Color(0xFFE8EFF5),
        AppColors.navy,
      ),
    };
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PurchaseCard extends StatelessWidget {
  const PurchaseCard({required this.purchase, required this.onTap, super.key});
  final PurchaseSummary purchase;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.condominiumName ?? 'Compra no mercado 24/7',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${localDate(purchase.createdAt)} às ${localTime(purchase.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.semantic.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(purchase.total),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.semantic.muted,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: StatusChip(status: purchase.status)),
                if (purchase.itemCount != null)
                  Text(
                    '${purchase.itemCount} ${purchase.itemCount == 1 ? 'item' : 'itens'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.semantic.muted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    required this.heroTag,
    super.key,
  });
  final ProductSummary product;
  final VoidCallback onTap;
  final String heroTag;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: SizedBox.expand(
                      child:
                          product.imageUrl == null || product.imageUrl!.isEmpty
                          ? Icon(
                              Icons.local_grocery_store_outlined,
                              size: 40,
                              color: context.semantic.muted,
                            )
                          : Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.image_not_supported_outlined,
                                color: context.semantic.muted,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.semantic.muted,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                if (product.isPromotion)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      'OFERTA',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (product.isPromotion)
              Text(
                money(product.originalPrice!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.semantic.muted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Text(
              money(product.price),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: product.isPromotion
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              product.unit,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
