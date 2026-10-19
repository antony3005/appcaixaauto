import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/client_registration.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
import '../../state/theme_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.controller,
    required this.data,
    super.key,
    this.themeController,
  });
  final ClientController controller;
  final ClientBootstrap data;
  final ThemeController? themeController;

  void _logout(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final name = data.user.fullName.isEmpty
        ? 'Cliente 24/7'
        : data.user.fullName;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          BrandHeader(
            padding: EdgeInsets.fromLTRB(
              canPop ? AppSpacing.s3 : AppSpacing.gutter,
              AppSpacing.s3,
              AppSpacing.gutter,
              AppSpacing.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canPop) const BackButton(color: AppColors.onNavy),
                Padding(
                  padding: EdgeInsets.only(
                    left: canPop ? AppSpacing.s1 : 0,
                    top: canPop ? AppSpacing.s2 : AppSpacing.s3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NavyAvatar(name: data.user.firstName),
                          const SizedBox(width: AppSpacing.s4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONTA 24/7',
                                  style: context.eyebrowStyle.copyWith(
                                    color: context.semantic.gold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    name,
                                    style: context.text.titleLarge?.copyWith(
                                      color: AppColors.onNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.apartment_rounded,
                              size: AppSizes.iconMd,
                              color: AppColors.onNavyMuted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Expanded(
                            child: Text(
                              data.condominium?.name ??
                                  'Condomínio não informado',
                              style: context.text.bodyMedium?.copyWith(
                                color: AppColors.onNavyMuted,
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
          ),
          SafeArea(
            top: false,
            child: AppContent(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s4,
                AppSpacing.gutter,
                AppSpacing.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListGroup(
                    children: [
                      InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'CPF',
                        value: _maskCpf(data.user.cpf),
                      ),
                      InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'E-mail',
                        value: _available(data.user.email),
                      ),
                      if (data.user.phone.isNotEmpty)
                        InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Telefone',
                          value: data.user.phone,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  const SectionHeader(title: 'Configurações'),
                  ListGroup(
                    children: [
                      if (data.capabilities.preferences)
                        AppListRow(
                          key: const ValueKey('profile-open-preferences'),
                          leading: const IconWell(icon: Icons.tune_rounded),
                          title: 'Preferências',
                          subtitle: 'Envio automático de comprovantes',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PreferencesPage(
                                controller: controller,
                                themeController: themeController,
                              ),
                            ),
                          ),
                        ),
                      if (themeController != null)
                        AnimatedBuilder(
                          animation: themeController!,
                          builder: (context, _) => AppListRow(
                            key: const ValueKey('profile-open-theme'),
                            leading: const IconWell(
                              icon: Icons.contrast_rounded,
                            ),
                            title: 'Tema',
                            subtitle: _themeLabel(themeController!.mode),
                            onTap: () =>
                                _showThemePicker(context, themeController!),
                          ),
                        ),
                      AppListRow(
                        leading: const IconWell(icon: Icons.gavel_rounded),
                        title: 'Termos e privacidade',
                        subtitle: 'Documentos oficiais do 24/7',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LegalDocumentsPage(
                              repository: controller.repository,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  SecondaryButton(
                    label: 'SAIR DA CONTA',
                    icon: Icons.logout_rounded,
                    destructive: true,
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({
    required this.controller,
    super.key,
    this.themeController,
  });
  final ClientController controller;
  final ThemeController? themeController;

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  PreferenceSettings? settings;
  String? error;
  bool loading = true;
  bool saving = false;
  bool saved = false;

  ClientRepository get repository => widget.controller.repository;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await repository.loadPreferences(
        widget.controller.session!,
      );
      if (mounted) setState(() => settings = value);
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar preferências.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> update(PreferenceSettings value) async {
    final previous = settings;
    setState(() {
      settings = value;
      saving = true;
      saved = false;
      error = null;
    });
    try {
      final result = await repository.updatePreferences(
        widget.controller.session!,
        value,
      );
      if (mounted) {
        setState(() {
          settings = result;
          saved = true;
        });
      }
    } on AppException catch (exception) {
      if (mounted) {
        setState(() {
          settings = previous;
          error = exception.message;
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _toggle({bool? email, bool? whatsapp}) => update(
    PreferenceSettings(
      autoEmail: email ?? settings!.autoEmail,
      autoWhatsapp: whatsapp ?? settings!.autoWhatsapp,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppTopBar(title: 'Preferências'),
    body: SafeArea(
      top: false,
      child: loading
          ? const AppContent(child: LoadingSection(rows: 2))
          : error != null && settings == null
          ? Center(
              child: ErrorState(message: error!, onRetry: load),
            )
          : ListView(
              children: [
                AppContent(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.s2,
                    AppSpacing.gutter,
                    AppSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Envio automático de comprovantes',
                          style: context.text.titleMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        'Receba o comprovante logo após cada compra no Terminal, nos contatos da sua conta.',
                        style: context.text.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      ListGroup(
                        children: [
                          _SwitchRow(
                            icon: Icons.chat_outlined,
                            title: 'Enviar por WhatsApp',
                            subtitle: 'Usa o telefone da sua conta',
                            value: settings!.autoWhatsapp,
                            onChanged: saving
                                ? null
                                : (value) => _toggle(whatsapp: value),
                          ),
                          _SwitchRow(
                            icon: Icons.mail_outline_rounded,
                            title: 'Enviar por e-mail',
                            subtitle: 'Usa o e-mail da sua conta',
                            value: settings!.autoEmail,
                            onChanged: saving
                                ? null
                                : (value) => _toggle(email: value),
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: AppAnimations.medium,
                        child: saving
                            ? const Padding(
                                key: ValueKey('saving'),
                                padding: EdgeInsets.only(top: AppSpacing.s3),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            : error != null
                            ? Padding(
                                key: const ValueKey('error'),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.s3,
                                ),
                                child: Notice(
                                  tone: NoticeTone.error,
                                  icon: Icons.error_outline_rounded,
                                  message: error!,
                                  live: true,
                                ),
                              )
                            : saved
                            ? const Padding(
                                key: ValueKey('saved'),
                                padding: EdgeInsets.only(top: AppSpacing.s3),
                                child: Notice(
                                  tone: NoticeTone.success,
                                  icon: Icons.check_circle_outline_rounded,
                                  message: 'Preferências salvas.',
                                  live: true,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (widget.themeController != null) ...[
                        const SizedBox(height: AppSpacing.section),
                        Semantics(
                          header: true,
                          child: Text('Tema', style: context.text.titleMedium),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        AnimatedBuilder(
                          animation: widget.themeController!,
                          builder: (context, _) => ThemeModeSelector(
                            controller: widget.themeController!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: AppListRow(
      leading: IconWell(icon: icon),
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      showChevron: false,
      trailing: Switch(value: value, onChanged: onChanged),
    ),
  );
}

/// Sistema · Claro · Escuro.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({required this.controller, super.key});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) => AppSegmented<ThemeMode>(
    label: 'Tema',
    selected: controller.mode,
    onChanged: controller.setMode,
    segments: const [
      (ThemeMode.system, 'Sistema', Icons.brightness_auto_outlined),
      (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Escuro', Icons.dark_mode_outlined),
    ],
  );
}

class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({required this.repository, super.key});
  final ClientRepository repository;

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  RegistrationLegalConfig? config;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await widget.repository.loadRegistrationLegalConfig();
      if (mounted) setState(() => config = value);
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppTopBar(title: 'Termos e privacidade'),
    body: SafeArea(
      top: false,
      child: config == null && error == null
          ? const AppContent(child: LoadingSection(rows: 2))
          : error != null
          ? Center(
              child: ErrorState(message: error!, onRetry: load),
            )
          : !config!.configured
          ? const AppContent(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'Documentos não publicados',
                message: 'Nenhum documento legal foi publicado pelo serviço.',
              ),
            )
          : ListView(
              children: [
                AppContent(
                  child: ListGroup(
                    children: [
                      AppListRow(
                        leading: const IconWell(
                          icon: Icons.description_outlined,
                        ),
                        title: 'Termos de Uso',
                        subtitle: 'Versão ${config!.termsVersion}',
                        trailing: Icon(
                          Icons.open_in_new_rounded,
                          size: AppSizes.iconMd,
                          color: context.semantic.muted,
                        ),
                        onTap: () => launchUrl(
                          config!.termsUrl!,
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      AppListRow(
                        leading: const IconWell(
                          icon: Icons.privacy_tip_outlined,
                        ),
                        title: 'Política de Privacidade',
                        subtitle: 'Versão ${config!.privacyVersion}',
                        trailing: Icon(
                          Icons.open_in_new_rounded,
                          size: AppSizes.iconMd,
                          color: context.semantic.muted,
                        ),
                        onTap: () => launchUrl(
                          config!.privacyUrl!,
                          mode: LaunchMode.externalApplication,
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

Future<void> _showThemePicker(
  BuildContext context,
  ThemeController controller,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  builder: (context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.s8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Tema', style: context.text.titleLarge),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            'A mudança vale na hora e fica salva neste aparelho.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s5),
          ThemeModeSelector(controller: controller),
        ],
      ),
    ),
  ),
);

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Seguir o sistema',
  ThemeMode.light => 'Claro',
  ThemeMode.dark => 'Escuro',
};
String _maskCpf(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return 'Não informado';
  return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
}

String _available(String value) => value.isEmpty ? 'Não informado' : value;
