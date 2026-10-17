import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
import '../../state/theme_controller.dart';
import '../benefits/benefits_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../purchases/purchases_page.dart';

class ClientShell extends StatelessWidget {
  const ClientShell({
    required this.controller,
    super.key,
    this.themeController,
  });
  final ClientController controller;
  final ThemeController? themeController;

  @override
  Widget build(BuildContext context) {
    if (controller.phase == LoadPhase.tenantLinkRequired) {
      return _TenantLinkRequiredPage(controller: controller);
    }
    if (controller.phase == LoadPhase.loading && controller.data == null) {
      return const Scaffold(
        body: SafeArea(
          child: AppContent(
            child: Padding(
              padding: EdgeInsets.only(top: 72),
              child: LoadingSection(rows: 5),
            ),
          ),
        ),
      );
    }
    if (controller.phase == LoadPhase.failure && controller.data == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ErrorState(
              message:
                  controller.errorMessage ??
                  'Não foi possível carregar seus dados.',
              onRetry: controller.refresh,
            ),
          ),
        ),
      );
    }
    final data = controller.data;
    if (data == null) return const SizedBox.shrink();
    final destinations = <_Destination>[
      _Destination(
        'Início',
        Icons.home_outlined,
        Icons.home_rounded,
        HomePage(controller: controller, data: data),
      ),
      _Destination(
        'Compras',
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        PurchasesPage(controller: controller, data: data),
      ),
      if (data.capabilities.benefits)
        _Destination(
          'Benefícios',
          Icons.stars_outlined,
          Icons.stars_rounded,
          BenefitsPage(controller: controller, data: data),
        ),
      _Destination(
        'Perfil',
        Icons.person_outline,
        Icons.person_rounded,
        ProfilePage(
          controller: controller,
          data: data,
          themeController: themeController,
        ),
      ),
    ];
    final selected = controller.navigationIndex.clamp(
      0,
      destinations.length - 1,
    );
    return Scaffold(
      body: IndexedStack(
        index: selected,
        children: destinations.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: controller.selectNavigation,
            destinations: destinations
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TenantLinkRequiredPage extends StatefulWidget {
  const _TenantLinkRequiredPage({required this.controller});

  final ClientController controller;

  @override
  State<_TenantLinkRequiredPage> createState() =>
      _TenantLinkRequiredPageState();
}

class _TenantLinkRequiredPageState extends State<_TenantLinkRequiredPage> {
  final _invitationController = TextEditingController();

  ClientController get controller => widget.controller;

  @override
  void dispose() {
    _invitationController.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    FocusScope.of(context).unfocus();
    final linked = await controller.linkTenant(_invitationController.text);
    if (mounted && linked) _invitationController.clear();
  }

  Future<void> _pasteInvitation() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final value = clipboard?.text?.trim();
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A área de transferência está vazia.')),
      );
      return;
    }
    _invitationController.text = value;
    controller.clearTenantLinkError();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Vincular condomínio'),
      actions: [
        IconButton(
          tooltip: 'Sair da conta',
          onPressed: controller.logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: AppContent(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadii.hero),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Vincule seu condomínio',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Cole o código enviado pelo administrador para liberar sua experiência no App247.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: .78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Código de convite',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  key: const ValueKey('tenant-invitation-token'),
                  controller: _invitationController,
                  enabled: !controller.tenantLinkInProgress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                  maxLength: 200,
                  onChanged: (_) => controller.clearTenantLinkError(),
                  onSubmitted: (_) => _link(),
                  decoration: InputDecoration(
                    hintText: 'Cole o convite recebido',
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Colar convite',
                      onPressed: controller.tenantLinkInProgress
                          ? null
                          : _pasteInvitation,
                      icon: const Icon(Icons.content_paste_rounded),
                    ),
                  ),
                ),
                if (controller.tenantLinkError != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.tenantLinkError!,
                      key: const ValueKey('tenant-link-error'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.tenantLinkInProgress
                        ? null
                        : _pasteInvitation,
                    icon: const Icon(Icons.content_paste_rounded),
                    label: const Text('COLAR CÓDIGO'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('tenant-link-submit'),
                    onPressed: controller.tenantLinkInProgress ? null : _link,
                    icon: controller.tenantLinkInProgress
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.apartment_rounded),
                    label: Text(
                      controller.tenantLinkInProgress
                          ? 'VINCULANDO...'
                          : 'VINCULAR CONTA',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed:
                      controller.tenantLinkRefreshInProgress ||
                          controller.tenantLinkInProgress
                      ? null
                      : controller.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('JÁ FUI VINCULADO, ATUALIZAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon, selectedIcon;
  final Widget page;
}
