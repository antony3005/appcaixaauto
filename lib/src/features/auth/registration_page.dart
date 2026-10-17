import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/client_registration.dart';
import '../../shared/app_widgets.dart';
import '../../state/registration_controller.dart';
import 'auth_widgets.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({required this.repository, super.key});

  final ClientRepository repository;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _cpfFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _phoneFormatter = _BrazilianPhoneInputFormatter();

  late final RegistrationController _registration;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  @override
  void initState() {
    super.initState();
    _registration = RegistrationController(widget.repository);
    _registration.loadLegalConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _cpfFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _registration.dispose();
    super.dispose();
  }

  String? _serverError(String field) => _registration.state.fieldErrors[field];

  String? _validateName(String? value) {
    final normalized = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return 'Informe seu nome completo.';
    final parts = normalized.split(' ');
    if (parts.length < 2) return 'Informe nome e sobrenome.';
    if (parts.first.length > 100 || parts.skip(1).join(' ').length > 100) {
      return 'O nome completo está muito longo.';
    }
    return _serverError('nome') ?? _serverError('sobrenome');
  }

  String? _validateCpf(String? _) {
    if (!isValidCpf(_cpfMask.getUnmaskedText())) return 'CPF inválido.';
    return _serverError('cpf');
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    return _serverError('email');
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && digits.length != 10 && digits.length != 11) {
      return 'Informe um telefone com DDD.';
    }
    return _serverError('telefone');
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'A senha deve ter no mínimo 6 caracteres.';
    }
    return _serverError('senha');
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Confirme sua senha.';
    if (value != _passwordController.text) return 'As senhas não coincidem.';
    return null;
  }

  void _focusFirstInvalidField() {
    final validations = <(String?, FocusNode)>[
      (_validateName(_nameController.text), _nameFocus),
      (_validateCpf(_cpfController.text), _cpfFocus),
      (_validateEmail(_emailController.text), _emailFocus),
      (_validatePhone(_phoneController.text), _phoneFocus),
      (_validatePassword(_passwordController.text), _passwordFocus),
      (
        _validateConfirmation(_confirmPasswordController.text),
        _confirmPasswordFocus,
      ),
    ];
    for (final validation in validations) {
      if (validation.$1 != null) {
        validation.$2.requestFocus();
        return;
      }
    }
  }

  Future<void> _submit() async {
    if (_registration.state.isBusy) return;
    final state = _registration.state;
    if (state.loadingLegalConfig || state.legalConfigError != null) return;
    if (state.legalConfig.configured &&
        (!_termsAccepted || !_privacyAccepted)) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      _focusFirstInvalidField();
      return;
    }

    FocusScope.of(context).unfocus();
    final request = ClientRegistrationRequest.fromForm(
      fullName: _nameController.text,
      cpf: _cpfMask.getUnmaskedText(),
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      legalConfig: state.legalConfig,
      termsAccepted: _termsAccepted,
      privacyAccepted: _privacyAccepted,
    );
    final succeeded = await _registration.submit(request);
    if (!mounted || succeeded) return;
    _formKey.currentState?.validate();
    if (_registration.state.fieldErrors.isNotEmpty) {
      _focusFirstInvalidField();
    }
  }

  void _clearErrors(Iterable<String> fields) {
    _registration.clearErrorsFor(fields);
  }

  Future<void> _openLegalDocument(Uri uri, String documentName) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Não foi possível abrir $documentName.')),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _registration,
    builder: (context, _) {
      final state = _registration.state;
      return PopScope(
        canPop: !state.isBusy,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: state.isBusy ? null : _goToLogin),
            title: const Text('Criar conta'),
          ),
          body: SafeArea(
            top: false,
            child: state.phase == RegistrationPhase.success
                ? _SuccessContent(onLogin: _goToLogin)
                : _buildForm(state),
          ),
        ),
      );
    },
  );

  void _goToLogin() => Navigator.of(context).pop();

  Widget _buildForm(RegistrationState state) => AppContent(
    child: AutofillGroup(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthBrandMark(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sua conta 24/7 começa aqui.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Use seus dados reais para acessar seu histórico e se identificar no Terminal.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.semantic.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.hero),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados da conta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'A senha fica somente durante este envio e não é salva no aparelho.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.semantic.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('registration-name'),
                      controller: _nameController,
                      focusNode: _nameFocus,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      inputFormatters: [LengthLimitingTextInputFormatter(201)],
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: _validateName,
                      onChanged: (_) =>
                          _clearErrors(const ['nome', 'sobrenome']),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('registration-cpf'),
                      controller: _cpfController,
                      focusNode: _cpfFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      inputFormatters: <TextInputFormatter>[_cpfMask],
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        hintText: '000.000.000-00',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _validateCpf,
                      onChanged: (_) => _clearErrors(const ['cpf']),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('registration-email'),
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'cliente@email.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: _validateEmail,
                      onChanged: (_) => _clearErrors(const ['email']),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('registration-phone'),
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [_phoneFormatter],
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp / telefone (opcional)',
                        hintText: '(75) 99999-9999',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: _validatePhone,
                      onChanged: (_) => _clearErrors(const ['telefone']),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('registration-password'),
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                      onChanged: (_) {
                        _clearErrors(const ['senha']);
                        if (_confirmPasswordController.text.isNotEmpty) {
                          _formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('registration-confirm-password'),
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmation
                              ? 'Mostrar confirmação'
                              : 'Ocultar confirmação',
                          onPressed: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: _validateConfirmation,
                    ),
                    if (state.loadingLegalConfig) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const LinearProgressIndicator(
                        key: ValueKey('legal-config-loading'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Carregando documentos legais...'),
                    ] else if (state.legalConfigError != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _LegalConfigError(
                        message: state.legalConfigError!,
                        onRetry: _registration.loadLegalConfig,
                      ),
                    ] else if (state.legalConfig.configured) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _LegalAcceptance(
                        termsAccepted: _termsAccepted,
                        privacyAccepted: _privacyAccepted,
                        termsVersion: state.legalConfig.termsVersion!,
                        privacyVersion: state.legalConfig.privacyVersion!,
                        onTermsChanged: state.isBusy
                            ? null
                            : (value) => setState(
                                () => _termsAccepted = value ?? false,
                              ),
                        onPrivacyChanged: state.isBusy
                            ? null
                            : (value) => setState(
                                () => _privacyAccepted = value ?? false,
                              ),
                        onOpenTerms: () => _openLegalDocument(
                          state.legalConfig.termsUrl!,
                          'os Termos de Uso',
                        ),
                        onOpenPrivacy: () => _openLegalDocument(
                          state.legalConfig.privacyUrl!,
                          'a Política de Privacidade',
                        ),
                      ),
                    ],
                    if (state.phase == RegistrationPhase.error &&
                        state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _RegistrationError(
                        message: state.message!,
                        showLoginAction:
                            state.failureKind ==
                            RegistrationFailureKind.cpfAlreadyRegistered,
                        onLogin: _goToLogin,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const ValueKey('registration-submit'),
                        onPressed:
                            state.isBusy ||
                                state.loadingLegalConfig ||
                                state.legalConfigError != null ||
                                (state.legalConfig.configured &&
                                    (!_termsAccepted || !_privacyAccepted))
                            ? null
                            : _submit,
                        child: state.isBusy
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.sm,
                                children: [
                                  SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                  Text('Criando conta...'),
                                ],
                              )
                            : Text(
                                MediaQuery.textScalerOf(context).scale(1) > 1.5
                                    ? 'CRIAR CONTA'
                                    : 'CRIAR MINHA CONTA',
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                key: const ValueKey('registration-login'),
                onPressed: state.isBusy ? null : _goToLogin,
                child: const Text('Já tenho conta — IR PARA LOGIN'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Cadastrar-se no app não identifica uma compra no Terminal.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.semantic.muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LegalAcceptance extends StatelessWidget {
  const _LegalAcceptance({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.termsVersion,
    required this.privacyVersion,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool termsAccepted;
  final bool privacyAccepted;
  final String termsVersion;
  final String privacyVersion;
  final ValueChanged<bool?>? onTermsChanged;
  final ValueChanged<bool?>? onPrivacyChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('legal-acceptance'),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadii.control),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          key: const ValueKey('accept-terms'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: termsAccepted,
          onChanged: onTermsChanged,
          title: const Text('Li e aceito os Termos de Uso.'),
          subtitle: _LegalDocumentLink(
            onTap: onOpenTerms,
            label: 'Ler Termos — versão $termsVersion',
          ),
        ),
        CheckboxListTile(
          key: const ValueKey('accept-privacy'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: privacyAccepted,
          onChanged: onPrivacyChanged,
          title: const Text('Li e aceito a Política de Privacidade.'),
          subtitle: _LegalDocumentLink(
            onTap: onOpenPrivacy,
            label: 'Ler Política — versão $privacyVersion',
          ),
        ),
      ],
    ),
  );
}

class _LegalDocumentLink extends StatelessWidget {
  const _LegalDocumentLink({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    link: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          label,
          softWrap: true,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
  );
}

class _LegalConfigError extends StatelessWidget {
  const _LegalConfigError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      key: const ValueKey('legal-config-error'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
        ],
      ),
    ),
  );
}

class _RegistrationError extends StatelessWidget {
  const _RegistrationError({
    required this.message,
    required this.showLoginAction,
    required this.onLogin,
  });

  final String message;
  final bool showLoginAction;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      key: const ValueKey('registration-error'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          if (showLoginAction) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const ValueKey('duplicate-cpf-login'),
              onPressed: onLogin,
              child: const Text('IR PARA LOGIN'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => AppContent(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        key: const ValueKey('registration-success'),
        children: [
          const AuthBrandMark(),
          const SizedBox(height: 72),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 42,
              color: AppColors.fresh,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Cadastro concluído',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sua conta foi criada. Entre com seu CPF e senha para continuar.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('success-login'),
              onPressed: onLogin,
              child: const Text('IR PARA LOGIN'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BrazilianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final end = digits.length > 11 ? 11 : digits.length;
    final limited = digits.substring(0, end);
    final buffer = StringBuffer();
    for (var index = 0; index < limited.length; index++) {
      if (index == 0) buffer.write('(');
      if (index == 2) buffer.write(') ');
      final dashIndex = limited.length > 10 ? 7 : 6;
      if (index == dashIndex) buffer.write('-');
      buffer.write(limited[index]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
