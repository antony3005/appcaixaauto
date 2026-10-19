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
final _points = NumberFormat.decimalPattern('pt_BR');

String money(double value) => _currency.format(value);
String localDate(DateTime value) => _date.format(value.toLocal());
String localTime(DateTime value) => _time.format(value.toLocal());
String points(int value) => _points.format(value);

const terminalReminder =
    'O app identifica, informa e recompensa. O Terminal vende.';

/// Coluna de conteúdo do telefone, centralizada em telas largas.
class AppContent extends StatelessWidget {
  const AppContent({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    this.maxWidth = AppSizes.contentMax,
  });
  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Botão de ícone circular com contorno (`c-icon-btn`).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: AppSizes.iconMd),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(44),
      minimumSize: const Size.square(44),
      backgroundColor: context.colors.surface,
      foregroundColor: context.colors.onSurface,
      shape: CircleBorder(side: BorderSide(color: context.colors.outline)),
    ),
  );
}

/// Barra superior: voltar · título `title-large` · uma ação.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.showBack,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool? showBack;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? Navigator.of(context).canPop();
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 68,
      leadingWidth: canPop ? 64 : 0,
      titleSpacing: canPop ? AppSpacing.s1 : AppSpacing.gutter,
      leading: canPop
          ? Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s3),
              child: Center(
                child: BackButton(
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(44),
                    minimumSize: const Size.square(44),
                    iconSize: AppSizes.iconMd,
                    backgroundColor: context.colors.surface,
                    foregroundColor: context.colors.onSurface,
                    shape: CircleBorder(
                      side: BorderSide(color: context.colors.outline),
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
        ],
      ),
      actions: [
        ...actions,
        if (actions.isNotEmpty) const SizedBox(width: AppSpacing.s3),
      ],
    );
  }
}

/// A placa branca com "24/7" em navy (`c-mark`).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'App 24/7',
    excludeSemantics: true,
    child: Container(
      height: large ? 56 : 28,
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.qrPaper,
        borderRadius: BorderRadius.circular(large ? AppRadii.md : 8),
        border: Border.all(color: const Color(0xFFDCE4EE)),
      ),
      // A marca é um logotipo: não acompanha a escala de texto do sistema.
      child: Text(
        '24/7',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
          fontSize: large ? 24 : 12,
          letterSpacing: -0.2,
          height: 1,
        ),
      ),
    ),
  );
}

/// Marca + "App Cliente", sobre o navy.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const BrandMark(),
      const SizedBox(width: AppSpacing.s2),
      Flexible(
        child: Text(
          'App Cliente',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleSmall?.copyWith(
            color: AppColors.onNavy,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    ],
  );
}

/// Cabeçalho navy das telas de marca (Login, Meu QR, Perfil, Boas-vindas).
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      AppSpacing.s5,
      AppSpacing.gutter,
      AppSpacing.s6,
    ),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg),
      ),
      border: context.isDark
          ? Border(bottom: BorderSide(color: context.colors.outline))
          : null,
    ),
    child: SafeArea(
      bottom: false,
      child: AppContent(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.onNavy),
          child: IconTheme.merge(
            data: const IconThemeData(color: AppColors.onNavy),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Cabeçalho de seção: `title-small` com um link opcional.
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
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 44),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.titleMedium),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ?trailing,
      ],
    ),
  );
}

enum NoticeTone { info, success, warning, error, gold }

/// Faixa suave e arredondada para contexto e confirmação (`c-notice`).
class Notice extends StatelessWidget {
  const Notice({
    required this.message,
    super.key,
    this.title,
    this.icon,
    this.tone = NoticeTone.info,
    this.live = false,
    this.action,
  });
  final String message;
  final String? title;
  final IconData? icon;
  final NoticeTone tone;
  final bool live;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final (background, accent, foreground) = switch (tone) {
      NoticeTone.info => (
        semantic.primarySoft,
        context.colors.primary,
        context.colors.onSurface,
      ),
      NoticeTone.success => (
        semantic.successContainer,
        semantic.success,
        context.colors.onSurface,
      ),
      NoticeTone.warning => (
        semantic.warningContainer,
        semantic.warning,
        context.colors.onSurface,
      ),
      NoticeTone.error => (
        semantic.errorContainer,
        context.colors.error,
        context.colors.onSurface,
      ),
      NoticeTone.gold => (
        semantic.goldContainer,
        semantic.onGold,
        semantic.onGold,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: live,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              ExcludeSemantics(
                child: Icon(icon, size: AppSizes.iconMd, color: accent),
              )
            else
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 2),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: context.text.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    message,
                    style: context.text.bodySmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.s1),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum WellTone { neutral, primary, gold, success, error }

/// Poço de ícone de 40px (`c-well`).
class IconWell extends StatelessWidget {
  const IconWell({
    required this.icon,
    super.key,
    this.tone = WellTone.neutral,
    this.size = AppSizes.well,
  });
  final IconData icon;
  final WellTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final (background, foreground) = switch (tone) {
      WellTone.neutral => (
        context.colors.surfaceContainerHigh,
        context.colors.onSurface,
      ),
      WellTone.primary => (semantic.primarySoft, context.colors.onSurface),
      WellTone.gold => (semantic.goldContainer, semantic.onGold),
      WellTone.success => (semantic.successContainer, semantic.success),
      WellTone.error => (semantic.errorContainer, context.colors.error),
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(icon, size: AppSizes.iconMd, color: foreground),
      ),
    );
  }
}

/// Linha de lista plana: poço · título e linha de apoio · ação (`c-li`).
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    super.key,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.showChevron,
  });
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final CrossAxisAlignment crossAxisAlignment;
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final chevron = showChevron ?? (onTap != null && trailing == null);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.s3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s3),
              trailing!,
            ],
            if (chevron) ...[
              const SizedBox(width: AppSpacing.s2),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.iconLg,
                  color: context.semantic.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: row,
      ),
    );
  }
}

/// Agrupa linhas com divisores de 1px, sem caixa em volta.
class ListGroup extends StatelessWidget {
  const ListGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const Divider(),
        children[index],
      ],
    ],
  );
}

/// Dado somente leitura: rótulo acima do valor.
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: AppSizes.iconMd,
                color: context.semantic.muted,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(
                      color: context.semantic.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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

enum TagTone { gold, success, primary, neutral }

/// Etiqueta em pílula ("+48 pts", "500 pontos").
class AppTag extends StatelessWidget {
  const AppTag({required this.label, super.key, this.tone = TagTone.gold});
  final String label;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final (background, foreground) = switch (tone) {
      TagTone.gold => (semantic.goldContainer, semantic.onGold),
      TagTone.success => (semantic.successContainer, context.colors.onSurface),
      TagTone.primary => (semantic.primarySoft, context.colors.onSurface),
      TagTone.neutral => (
        context.colors.surfaceContainerHigh,
        context.colors.onSurface,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: context.text.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

enum StatusTone { success, warning, error, neutral }

/// Ponto de 6px + palavra: a cor nunca é o único sinal (`c-status`).
class StatusDot extends StatelessWidget {
  const StatusDot({required this.label, required this.tone, super.key});
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusTone.success => context.semantic.success,
      StatusTone.warning => context.semantic.warning,
      StatusTone.error => context.colors.error,
      StatusTone.neutral => context.semantic.muted,
    };
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});
  final PurchaseStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      PurchaseStatus.approved => ('Aprovada', StatusTone.success),
      PurchaseStatus.canceled => ('Cancelada', StatusTone.error),
      PurchaseStatus.failed => ('Não aprovada', StatusTone.error),
      PurchaseStatus.expired => ('Expirada', StatusTone.warning),
      PurchaseStatus.refunded => ('Reembolsada', StatusTone.neutral),
      PurchaseStatus.actionRequired => ('Ação necessária', StatusTone.warning),
      PurchaseStatus.pending ||
      PurchaseStatus.created ||
      PurchaseStatus.atTerminal => (
        'Aguardando confirmação',
        StatusTone.warning,
      ),
      PurchaseStatus.unknown => ('Em atualização', StatusTone.neutral),
    };
    return StatusDot(label: label, tone: tone);
  }
}

/// Cartão dourado de saldo (pontos ou cashback). Único lugar com cartão
/// além do tile do Meu QR.
class PointsCard extends StatelessWidget {
  const PointsCard({
    required this.label,
    required this.value,
    super.key,
    this.unit,
    this.caption,
    this.onTap,
  });
  final String label, value;
  final String? unit, caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final onGold = semantic.onGold;
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: semantic.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.eyebrowStyle.copyWith(color: onGold),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.s1),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.iconSm,
                  color: onGold,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: context.text.titleMedium?.copyWith(color: onGold),
                    ),
                ],
              ),
              style: context.text.displaySmall?.copyWith(color: onGold),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: onGold),
            ),
          ],
        ],
      ),
    );
    return Material(
      color: semantic.goldContainer,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Tile navy do Meu QR, ação principal do Início.
class QrTile extends StatelessWidget {
  const QrTile({required this.onTap, super.key});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Meu QR. Identifique-se no Terminal',
    excludeSemantics: true,
    child: Material(
      color: AppColors.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: context.isDark
            ? BorderSide(color: context.colors.outline)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.onNavy.withValues(alpha: .12),
        highlightColor: AppColors.onNavy.withValues(alpha: .06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.qrPaper,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.qrInk,
                  size: AppSizes.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Meu QR',
                style: context.text.titleMedium?.copyWith(
                  color: AppColors.onNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Identifique-se no Terminal',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.onNavyMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Iniciais em círculo translúcido sobre o navy.
class NavyAvatar extends StatelessWidget {
  const NavyAvatar({required this.name, super.key, this.size = 56});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .2)),
      ),
      child: Text(
        name.trim().isEmpty ? '24' : name.trim().characters.first.toUpperCase(),
        style: context.text.titleLarge?.copyWith(
          color: AppColors.onNavy,
          fontSize: size * .36,
        ),
      ),
    ),
  );
}

/// Botão principal em pílula. Ao enviar, o ícone vira o loader de pontos.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.expand = true,
    this.navy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading, expand, navy;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = navy ? AppColors.onNavy : context.colors.onPrimary;
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: navy
          ? FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.onNavy,
              disabledBackgroundColor: AppColors.navy.withValues(alpha: .5),
              disabledForegroundColor: AppColors.onNavy,
              side: context.isDark
                  ? BorderSide(color: context.colors.outline)
                  : null,
            )
          : loading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: context.colors.primary,
              disabledForegroundColor: foreground,
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            DotsLoader(color: foreground),
            const SizedBox(width: AppSpacing.s2),
          ] else if (icon != null) ...[
            Icon(icon, size: AppSizes.iconMd),
            const SizedBox(width: AppSpacing.s2),
          ],
          Flexible(
            child: Text(
              loading ? (loadingLabel ?? label) : label,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botão de contorno em pílula, opcionalmente destrutivo.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.destructive = false,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive, expand;

  @override
  Widget build(BuildContext context) {
    final style = destructive
        ? OutlinedButton.styleFrom(foregroundColor: context.colors.error)
        : null;
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Chip de filtro: 32px visíveis, 48px de área de toque.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: SizedBox(
          height: AppSizes.tapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppAnimations.short,
              curve: AppAnimations.standard,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ),
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Controle segmentado em pílula (`c-seg`).
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.label,
    super.key,
  });
  final List<(T, String, IconData)> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    container: true,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _Segment(
                label: segment.$2,
                icon: segment.$3,
                selected: segment.$1 == selected,
                onTap: onChanged == null ? null : () => onChanged!(segment.$1),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.onSurface : context.semantic.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppAnimations.short,
        curve: AppAnimations.standard,
        decoration: BoxDecoration(
          color: selected ? context.colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected ? context.semantic.cardShadow : null,
          border: selected && context.isDark
              ? Border.all(color: context.colors.outline)
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: AppSizes.iconSm, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
  final String label;
  final IconData icon, selectedIcon;
}

/// Barra inferior: o item ativo vira um bloco `primary-soft`.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(top: BorderSide(color: context.colors.outline)),
      boxShadow: context.semantic.raisedShadow,
    ),
    child: SafeArea(
      top: false,
      child: AppContent(
        padding: const EdgeInsets.all(AppSpacing.s2),
        child: SizedBox(
          height: AppSizes.navHeight - AppSpacing.s4,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _NavItem(
                    item: items[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.onSurface : context.semantic.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? context.semantic.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: AppSizes.iconLg,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador circular pequeno (página ou lista carregando).
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.color, this.trackColor, this.label});
  final Color? color, trackColor;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label ?? 'Carregando',
    liveRegion: true,
    child: SizedBox.square(
      dimension: 40,
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: color ?? context.colors.primary,
            backgroundColor: trackColor ?? context.colors.surfaceContainer,
          ),
        ),
      ),
    ),
  );
}

Duration _loaderPeriod(BuildContext context, Duration base) =>
    MediaQuery.maybeDisableAnimationsOf(context) == true
    ? const Duration(seconds: 3)
    : base;

/// Três pontos pulsando, dentro de botões que estão enviando.
class DotsLoader extends StatefulWidget {
  const DotsLoader({super.key, this.color});
  final Color? color;

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller
      ..duration = _loaderPeriod(context, const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.primary;
    return Semantics(
      label: 'Carregando',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              Opacity(
                opacity: _dotOpacity(_controller.value, index),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _dotOpacity(double t, int index) {
    final phase = (t - index * .15) % 1;
    final wave = phase < .5 ? phase * 2 : (1 - phase) * 2;
    return .35 + .65 * Curves.easeInOut.transform(wave);
  }
}

/// Bloco de esqueleto com brilho suave.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadii.sm,
  });
  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller
      ..duration = _loaderPeriod(context, const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: .45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
    child: Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Linhas-esqueleto no formato das linhas de lista.
class LoadingSection extends StatelessWidget {
  const LoadingSection({super.key, this.rows = 3});
  final int rows;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var index = 0; index < rows; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
              child: Row(
                children: [
                  const Skeleton(height: 40, width: 40),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: index.isEven ? .7 : .55,
                          child: const Skeleton(height: 14),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        const FractionallySizedBox(
                          widthFactor: .4,
                          child: Skeleton(height: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class LoadingTile extends StatelessWidget {
  const LoadingTile({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) =>
      Skeleton(height: height, radius: AppRadii.md);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSizes.iconLg,
                color: context.colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.muted,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.s4),
            action!,
          ],
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
    padding: const EdgeInsets.all(AppSpacing.s6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.semantic.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: AppSizes.iconLg,
              color: context.colors.error,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        SecondaryButton(
          onPressed: onRetry,
          icon: Icons.refresh_rounded,
          label: 'TENTAR NOVAMENTE',
          expand: false,
        ),
      ],
    ),
  );
}

/// Uma compra no histórico (`c-row`): plana, separada por divisor.
class PurchaseCard extends StatelessWidget {
  const PurchaseCard({required this.purchase, required this.onTap, super.key});
  final PurchaseSummary purchase;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final meta = [
      purchase.condominiumName ?? 'Mercado 24/7',
      localTime(purchase.createdAt),
      if (purchase.itemCount != null)
        '${purchase.itemCount} ${purchase.itemCount == 1 ? 'item' : 'itens'}',
    ].join(' · ');
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
          child: Row(
            children: [
              const IconWell(icon: Icons.receipt_long_rounded),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${localDate(purchase.createdAt)} — ${money(purchase.total)}',
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    StatusChip(status: purchase.status),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: context.semantic.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de compras com divisores entre as linhas.
class PurchaseList extends StatelessWidget {
  const PurchaseList({
    required this.purchases,
    required this.onOpen,
    super.key,
  });
  final List<PurchaseSummary> purchases;
  final ValueChanged<PurchaseSummary> onOpen;

  @override
  Widget build(BuildContext context) => ListGroup(
    children: [
      for (final purchase in purchases)
        PurchaseCard(purchase: purchase, onTap: () => onOpen(purchase)),
    ],
  );
}

/// Tile do catálogo: informa preço e disponibilidade. Sem botão de compra.
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
  Widget build(BuildContext context) {
    final discount = product.isPromotion
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: ProductImage(url: product.imageUrl),
                      ),
                      if (discount > 0)
                        Positioned(
                          top: AppSpacing.s2,
                          left: AppSpacing.s2,
                          child: OfferBadge(label: '-$discount%'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                categoryLabel(product.category).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.eyebrowStyle.copyWith(
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.s1),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.s1,
                children: [
                  Text(
                    money(product.price),
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: product.isPromotion ? context.colors.error : null,
                    ),
                  ),
                  if (product.isPromotion)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        money(product.originalPrice!),
                        style: context.text.bodySmall?.copyWith(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                ],
              ),
              if (product.unit.isNotEmpty)
                Text(
                  product.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selo de oferta: `error-soft` / `error`, `radius-xs`.
class OfferBadge extends StatelessWidget {
  const OfferBadge({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: context.semantic.errorContainer,
      borderRadius: BorderRadius.circular(AppRadii.xs),
    ),
    child: Text(
      label,
      style: context.text.labelMedium?.copyWith(
        color: context.colors.error,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
}

/// Foto do produto num poço `surface-low`, com ícone quando falta imagem.
class ProductImage extends StatelessWidget {
  const ProductImage({required this.url, super.key, this.iconSize = 36});
  final String? url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(IconData icon) => Center(
      child: Icon(icon, size: iconSize, color: context.semantic.muted),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: ColoredBox(
        color: context.colors.surfaceContainerLow,
        child: url == null || url!.isEmpty
            ? placeholder(Icons.inventory_2_outlined)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) =>
                    placeholder(Icons.image_not_supported_outlined),
              ),
      ),
    );
  }
}

/// Totais de uma compra: rótulos em `muted`, valores à direita.
class OrderSummary extends StatelessWidget {
  const OrderSummary({
    required this.subtotal,
    required this.discount,
    required this.total,
    super.key,
  });
  final double subtotal, discount, total;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.muted,
              ),
            ),
          ),
          Text(
            value,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        line('Subtotal', money(subtotal)),
        if (discount > 0)
          line(
            'Descontos e promoções',
            '− ${money(discount)}',
            color: context.semantic.success,
          ),
        const SizedBox(height: AppSpacing.s2),
        const Divider(),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Expanded(child: Text('Total', style: context.text.titleMedium)),
            Text(
              money(total),
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String categoryLabel(String raw) {
  if (raw.isEmpty) return 'Sem categoria';
  return raw
      .toLowerCase()
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
