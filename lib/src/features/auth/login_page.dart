import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../core/theme/app_theme.dart';
import '../../state/client_controller.dart';
import '../../shared/app_widgets.dart';
import 'password_recovery_page.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.controller, super.key});
  final ClientController controller;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final cpfController = TextEditingController();
  final passwordController = TextEditingController();
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  bool obscure = true;

  @override
  void dispose() {
    cpfController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.login(
      cpf: cpfMask.getUnmaskedText(),
      password: passwordController.text,
    );
  }

  void openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RegistrationPage(repository: widget.controller.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 300),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppRadii.hero),
                        bottomRight: Radius.circular(AppRadii.hero),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LoginBrand(onPrimary: scheme.onPrimary),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Seu condomínio,\nna palma da mão.',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: scheme.onPrimary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Identifique-se no Terminal, acompanhe compras e aproveite seus benefícios.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: scheme.onPrimary.withValues(alpha: .78),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: const [
                            _HeroPill(
                              icon: Icons.qr_code_2_rounded,
                              label: 'QR rápido',
                            ),
                            _HeroPill(
                              icon: Icons.receipt_long_rounded,
                              label: 'Compras',
                            ),
                            _HeroPill(
                              icon: Icons.stars_rounded,
                              label: 'Benefícios',
                              premium: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppContent(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.lg,
                        0,
                        AppSpacing.xl,
                      ),
                      child: Form(
                        key: formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acesse sua conta',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Use seu CPF e senha para continuar.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: context.semantic.muted),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: cpfController,
                                inputFormatters: <TextInputFormatter>[cpfMask],
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                decoration: const InputDecoration(
                                  labelText: 'CPF',
                                  hintText: '000.000.000-00',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (_) =>
                                    cpfMask.getUnmaskedText().length == 11
                                    ? null
                                    : 'Informe um CPF com 11 números.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => submit(),
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: obscure
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () =>
                                        setState(() => obscure = !obscure),
                                    icon: Icon(
                                      obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) => (value?.length ?? 0) >= 8
                                    ? null
                                    : 'Informe sua senha.',
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const ValueKey('open-password-recovery'),
                                  onPressed: widget.controller.loginInProgress
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                PasswordRecoveryPage(
                                                  repository: widget
                                                      .controller
                                                      .repository,
                                                ),
                                          ),
                                        ),
                                  child: const Text('Esqueci minha senha'),
                                ),
                              ),
                              if (widget.controller.errorMessage != null)
                                _LoginError(
                                  message: widget.controller.errorMessage!,
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: widget.controller.loginInProgress
                                      ? null
                                      : submit,
                                  icon: widget.controller.loginInProgress
                                      ? SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: scheme.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward_rounded),
                                  label: Text(
                                    widget.controller.loginInProgress
                                        ? 'ENTRANDO...'
                                        : 'Entrar',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Ainda não tem uma conta?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: context.semantic.muted,
                                        ),
                                  ),
                                  TextButton(
                                    key: const ValueKey('open-registration'),
                                    onPressed: widget.controller.loginInProgress
                                        ? null
                                        : openRegistration,
                                    child: const Text('Cadastre-se'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _LoginBrand extends StatelessWidget {
  const _LoginBrand({required this.onPrimary});
  final Color onPrimary;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.semantic.gold,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Text(
          '247',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.semantic.onGold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        'App Cliente',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: onPrimary),
      ),
    ],
  );
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    this.premium = false,
  });
  final IconData icon;
  final String label;
  final bool premium;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: premium
          ? context.semantic.gold.withValues(alpha: .18)
          : AppColors.darkText.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      border: Border.all(
        color: premium
            ? context.semantic.gold.withValues(alpha: .34)
            : AppColors.darkText.withValues(alpha: .14),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: premium ? context.semantic.gold : AppColors.darkText,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: premium ? context.semantic.gold : AppColors.darkText,
          ),
        ),
      ],
    ),
  );
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
