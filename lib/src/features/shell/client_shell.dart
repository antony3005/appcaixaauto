import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
import '../../state/theme_controller.dart';
import '../catalog/catalog_pages.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../purchases/purchases_page.dart';
import '../qr/customer_identification_page.dart';

/// As quatro abas do App Cliente. Catálogo e Meu QR dependem das
/// capacidades liberadas para o condomínio.
enum ShellTab { home, catalog, qr, purchases, profile }

List<ShellTab> shellTabs(ClientBootstrap data) => [
  ShellTab.home,
  if (data.capabilities.catalog) ShellTab.catalog,
  if (data.capabilities.identificationQr) ShellTab.qr,
  ShellTab.purchases,
  ShellTab.profile,
];

/// Seleciona uma aba pelo nome; ignora abas desligadas.
void selectShellTab(ClientController controller, ShellTab tab) {
  final data = controller.data;
  if (data == null) return;
  final index = shellTabs(data).indexOf(tab);
  if (index >= 0) controller.selectNavigation(index);
}

class ClientShell extends StatefulWidget {
  const ClientShell({
    required this.controller,
    super.key,
    this.themeController,
  });
  final ClientController controller;
  final ThemeController? themeController;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  final _visited = <ShellTab>{ShellTab.home};

  ClientController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    if (controller.phase == LoadPhase.tenantLinkRequired) {
      return _TenantLinkRequiredPage(controller: controller);
    }
    if (controller.phase == LoadPhase.loading && controller.data == null) {
      return const Scaffold(
        body: SafeArea(
          child: AppContent(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.s10,
              AppSpacing.gutter,
              0,
            ),
            child: LoadingSection(rows: 5),
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
    final tabs = shellTabs(data);
    final selected = controller.navigationIndex.clamp(0, tabs.length - 1);
    _visited.add(tabs[selected]);
    return Scaffold(
      body: IndexedStack(
        index: selected,
        children: [
          for (final tab in tabs)
            _visited.contains(tab) ? _page(tab, data) : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: selected,
        onSelected: controller.selectNavigation,
        items: [for (final tab in tabs) _item(tab)],
      ),
    );
  }

  Widget _page(ShellTab tab, ClientBootstrap data) => switch (tab) {
    ShellTab.home => HomePage(
      controller: controller,
      data: data,
      themeController: widget.themeController,
    ),
    ShellTab.catalog => CatalogPage(
      data: data,
      repository: controller.repository,
      session: controller.session!,
    ),
    ShellTab.qr => CustomerIdentificationPage(
      repository: controller.repository,
      session: controller.session!,
      loyaltyMode: data.loyaltyMode,
    ),
    ShellTab.purchases => PurchasesPage(controller: controller, data: data),
    ShellTab.profile => ProfilePage(
      controller: controller,
      data: data,
      themeController: widget.themeController,
    ),
  };

  AppNavItem _item(ShellTab tab) => switch (tab) {
    ShellTab.home => const AppNavItem(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    ShellTab.catalog => const AppNavItem(
      label: 'Catálogo',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    ShellTab.qr => const AppNavItem(
      label: 'Meu QR',
      icon: Icons.qr_code_2_outlined,
      selectedIcon: Icons.qr_code_2_rounded,
    ),
    ShellTab.purchases => const AppNavItem(
      label: 'Compras',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    ShellTab.profile => const AppNavItem(
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  };
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
  Widget build(BuildContext context) {
    final busy = controller.tenantLinkInProgress;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Vincular condomínio',
        showBack: false,
        actions: [
          AppIconButton(
            tooltip: 'Sair da conta',
            onPressed: controller.logout,
            icon: Icons.logout_rounded,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: AppContent(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.s2,
              AppSpacing.gutter,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: IconWell(
                    icon: Icons.apartment_rounded,
                    tone: WellTone.primary,
                    size: 56,
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  'Vincule seu condomínio',
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'Cole o código de convite enviado pelo administrador para liberar sua experiência no 24/7.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.semantic.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                TextField(
                  key: const ValueKey('tenant-invitation-token'),
                  controller: _invitationController,
                  enabled: !busy,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                  maxLength: 200,
                  onChanged: (_) => controller.clearTenantLinkError(),
                  onSubmitted: (_) => _link(),
                  decoration: InputDecoration(
                    labelText: 'Código de convite',
                    hintText: 'Cole o convite recebido',
                    prefixIcon: const Icon(Icons.link_rounded),
                    counterText: '',
                    enabledBorder: controller.tenantLinkError == null
                        ? null
                        : UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: context.colors.error,
                              width: 2,
                            ),
                          ),
                    suffixIcon: IconButton(
                      tooltip: 'Colar convite',
                      onPressed: busy ? null : _pasteInvitation,
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        size: AppSizes.iconMd,
                      ),
                    ),
                  ),
                ),
                if (controller.tenantLinkError != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.tenantLinkError!,
                      key: const ValueKey('tenant-link-error'),
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                PrimaryButton(
                  key: const ValueKey('tenant-link-submit'),
                  label: 'VINCULAR CONTA',
                  loadingLabel: 'VINCULANDO...',
                  icon: Icons.apartment_rounded,
                  loading: busy,
                  onPressed: _link,
                ),
                const SizedBox(height: AppSpacing.s3),
                SecondaryButton(
                  label: 'COLAR CÓDIGO',
                  icon: Icons.content_paste_rounded,
                  onPressed: busy ? null : _pasteInvitation,
                ),
                const SizedBox(height: AppSpacing.s4),
                Center(
                  child: TextButton.icon(
                    onPressed: controller.tenantLinkRefreshInProgress || busy
                        ? null
                        : controller.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('JÁ FUI VINCULADO, ATUALIZAR'),
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
