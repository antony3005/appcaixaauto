import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/app_widgets.dart';
import '../../state/client_controller.dart';
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
  final cpfFocus = FocusNode();
  final passwordFocus = FocusNode();
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  bool obscure = true;

  @override
  void dispose() {
    cpfController.dispose();
    passwordController.dispose();
    cpfFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  String? _validateCpf(String? _) => cpfMask.getUnmaskedText().length == 11
      ? null
      : 'Informe um CPF com 11 números.';

  String? _validatePassword(String? value) =>
      (value?.length ?? 0) >= 8 ? null : 'Informe sua senha.';

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      (_validateCpf(null) != null ? cpfFocus : passwordFocus).requestFocus();
      return;
    }
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

  void openRecovery() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PasswordRecoveryPage(repository: widget.controller.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.controller.loginInProgress;
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandHeader(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s6,
                AppSpacing.gutter,
                AppSpacing.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLockup(),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Seu condomínio, mais inteligente todo dia.',
                    style: context.text.headlineSmall?.copyWith(
                      color: AppColors.onNavy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'Identifique-se no Terminal, acompanhe compras e receba recompensas.',
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.onNavyMuted,
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
                  AppSpacing.s6,
                  AppSpacing.gutter,
                  AppSpacing.s6,
                ),
                child: Form(
                  key: formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Acesse sua conta',
                          style: context.text.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.s1),
                        Text(
                          'Use seu CPF e senha para continuar.',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.semantic.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        TextFormField(
                          controller: cpfController,
                          focusNode: cpfFocus,
                          enabled: !busy,
                          inputFormatters: <TextInputFormatter>[cpfMask],
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'CPF',
                            hintText: '000.000.000-00',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _validateCpf,
                          onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        TextFormField(
                          controller: passwordController,
                          focusNode: passwordFocus,
                          enabled: !busy,
                          obscureText: obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => submit(),
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Sua senha',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                                size: AppSizes.iconMd,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const ValueKey('open-password-recovery'),
                            onPressed: busy ? null : openRecovery,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        if (widget.controller.errorMessage != null) ...[
                          Notice(
                            tone: NoticeTone.error,
                            icon: Icons.error_outline_rounded,
                            message: widget.controller.errorMessage!,
                            live: true,
                          ),
                          const SizedBox(height: AppSpacing.s4),
                        ] else
                          const SizedBox(height: AppSpacing.s2),
                        PrimaryButton(
                          key: const ValueKey('login-submit'),
                          label: 'ACESSAR',
                          loadingLabel: 'ENTRANDO',
                          icon: Icons.arrow_forward_rounded,
                          loading: busy,
                          onPressed: submit,
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        const Notice(message: terminalReminder),
                        const SizedBox(height: AppSpacing.s4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Ainda não tem conta?',
                              style: context.text.bodyMedium?.copyWith(
                                color: context.semantic.muted,
                              ),
                            ),
                            TextButton(
                              key: const ValueKey('open-registration'),
                              onPressed: busy ? null : openRegistration,
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
    );
  }
}
