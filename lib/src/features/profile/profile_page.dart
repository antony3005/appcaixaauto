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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: SafeArea(
      top: false,
      child: AppContent(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(AppRadii.hero),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
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
                              : data.user.firstName[0].toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.darkText),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONTA APP247',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: context.semantic.gold,
                                    letterSpacing: 1,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              data.user.fullName.isEmpty
                                  ? 'Cliente 24/7'
                                  : data.user.fullName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: AppColors.darkText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 18,
                        color: AppColors.darkMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          data.condominium?.name ?? 'Condomínio não informado',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.darkMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                children: [
                  _DataRow(
                    icon: Icons.badge_outlined,
                    label: 'CPF',
                    value: _maskCpf(data.user.cpf),
                  ),
                  const Divider(),
                  _DataRow(
                    icon: Icons.mail_outline,
                    label: 'E-mail',
                    value: _available(data.user.email),
                  ),
                  if (data.user.phone.isNotEmpty) ...[
                    const Divider(),
                    _DataRow(
                      icon: Icons.phone_outlined,
                      label: 'Telefone',
                      value: data.user.phone,
                    ),
                  ],
                  if (data.condominium != null) ...[
                    const Divider(),
                    _DataRow(
                      icon: Icons.apartment_outlined,
                      label: 'Condomínio',
                      value: data.condominium!.name,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Configurações',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (data.capabilities.preferences)
              _ActionRow(
                key: const ValueKey('profile-open-preferences'),
                icon: Icons.tune_rounded,
                title: 'Preferências',
                subtitle: 'Envio automático de comprovantes',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PreferencesPage(controller: controller),
                  ),
                ),
              ),
            if (themeController != null)
              _ActionRow(
                key: const ValueKey('profile-open-theme'),
                icon: Icons.contrast_rounded,
                title: 'Tema',
                subtitle: _themeLabel(themeController!.mode),
                onTap: () => _showThemePicker(context, themeController!),
              ),
            _ActionRow(
              icon: Icons.gavel_outlined,
              title: 'Termos e privacidade',
              subtitle: 'Documentos oficiais do App247',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      LegalDocumentsPage(repository: controller.repository),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    ),
  );
}

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({required this.controller, super.key});
  final ClientController controller;

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  PreferenceSettings? settings;
  String? error;
  bool loading = true;
  bool saving = false;

  ClientFeatureRepository get repository =>
      widget.controller.repository as ClientFeatureRepository;

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
      error = null;
    });
    try {
      final saved = await repository.updatePreferences(
        widget.controller.session!,
        value,
      );
      if (mounted) setState(() => settings = saved);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preferências')),
    body: SafeArea(
      top: false,
      child: loading
          ? const AppContent(child: LoadingSection(rows: 2))
          : error != null && settings == null
          ? Center(
              child: ErrorState(message: error!, onRetry: load),
            )
          : AppContent(
              child: ListView(
                children: [
                  Text(
                    'Comprovantes automáticos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Escolha os canais reais cadastrados para receber o comprovante após compras elegíveis.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.semantic.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enviar por e-mail'),
                          subtitle: const Text('Usa o e-mail da sua conta'),
                          value: settings!.autoEmail,
                          onChanged: saving
                              ? null
                              : (value) => update(
                                  PreferenceSettings(
                                    autoEmail: value,
                                    autoWhatsapp: settings!.autoWhatsapp,
                                  ),
                                ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Enviar por WhatsApp'),
                          subtitle: const Text('Usa o telefone da sua conta'),
                          value: settings!.autoWhatsapp,
                          onChanged: saving
                              ? null
                              : (value) => update(
                                  PreferenceSettings(
                                    autoEmail: settings!.autoEmail,
                                    autoWhatsapp: value,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (saving) ...[
                    const SizedBox(height: AppSpacing.md),
                    const LinearProgressIndicator(),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    ),
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
    appBar: AppBar(title: const Text('Termos e privacidade')),
    body: SafeArea(
      top: false,
      child: AppContent(
        child: config == null && error == null
            ? const LoadingSection(rows: 2)
            : error != null
            ? ErrorState(message: error!, onRetry: load)
            : !config!.configured
            ? const EmptyState(
                icon: Icons.description_outlined,
                title: 'Documentos não publicados',
                message: 'Nenhum documento legal foi publicado pelo serviço.',
              )
            : ListView(
                children: [
                  _ActionRow(
                    icon: Icons.description_outlined,
                    title: 'Termos de Uso',
                    subtitle: 'Versão ${config!.termsVersion}',
                    onTap: () => launchUrl(
                      config!.termsUrl!,
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  _ActionRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de Privacidade',
                    subtitle: 'Versão ${config!.privacyVersion}',
                    onTap: () => launchUrl(
                      config!.privacyUrl!,
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Icon(icon),
    ),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

Future<void> _showThemePicker(
  BuildContext context,
  ThemeController controller,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  builder: (context) => RadioGroup<ThemeMode>(
    groupValue: controller.mode,
    onChanged: (value) {
      if (value == null) return;
      controller.setMode(value);
      Navigator.of(context).pop();
    },
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleLarge),
          const RadioListTile(value: ThemeMode.system, title: Text('Sistema')),
          const RadioListTile(value: ThemeMode.light, title: Text('Claro')),
          const RadioListTile(value: ThemeMode.dark, title: Text('Escuro')),
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
