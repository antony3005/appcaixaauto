import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/client_registration.dart';
import '../../shared/app_widgets.dart';
import '../../state/registration_controller.dart';

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
          appBar: const AppTopBar(title: 'Criar conta', showBack: true),
          body: SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: AppAnimations.medium,
              switchInCurve: AppAnimations.standard,
              child: state.phase == RegistrationPhase.success
                  ? _SuccessContent(onLogin: _goToLogin)
                  : _buildForm(state),
            ),
          ),
        ),
      );
    },
  );

  void _goToLogin() => Navigator.of(context).pop();

  bool _canSubmit(RegistrationState state) =>
      !state.isBusy &&
      !state.loadingLegalConfig &&
      state.legalConfigError == null &&
      (!state.legalConfig.configured || (_termsAccepted && _privacyAccepted));

  Widget _buildForm(RegistrationState state) => AutofillGroup(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: AppContent(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.s2,
          AppSpacing.gutter,
          AppSpacing.s8,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sua conta 24/7 começa aqui.',
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Use seus dados reais para acessar seu histórico e se identificar no Terminal.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
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
                  hintText: 'Nome e sobrenome',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: _validateName,
                onChanged: (_) => _clearErrors(const ['nome', 'sobrenome']),
              ),
              const SizedBox(height: AppSpacing.s5),
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
              const SizedBox(height: AppSpacing.s5),
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
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validateEmail,
                onChanged: (_) => _clearErrors(const ['email']),
              ),
              const SizedBox(height: AppSpacing.s5),
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
              const SizedBox(height: AppSpacing.s5),
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
                  hintText: 'Mínimo de 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppSizes.iconMd,
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
              const SizedBox(height: AppSpacing.s5),
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
                  hintText: 'Repita a senha',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
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
                      size: AppSizes.iconMd,
                    ),
                  ),
                ),
                validator: _validateConfirmation,
              ),
              const SizedBox(height: AppSpacing.s6),
              const Notice(
                icon: Icons.shield_outlined,
                message:
                    'A senha fica somente durante este envio e não é salva no aparelho.',
              ),
              if (state.loadingLegalConfig) ...[
                const SizedBox(height: AppSpacing.s6),
                const LinearProgressIndicator(
                  key: ValueKey('legal-config-loading'),
                  minHeight: 3,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'Carregando documentos legais...',
                  style: context.text.bodySmall,
                ),
              ] else if (state.legalConfigError != null) ...[
                const SizedBox(height: AppSpacing.s6),
                Notice(
                  key: const ValueKey('legal-config-error'),
                  tone: NoticeTone.error,
                  icon: Icons.error_outline_rounded,
                  live: true,
                  message: state.legalConfigError!,
                  action: TextButton(
                    onPressed: _registration.loadLegalConfig,
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ] else if (state.legalConfig.configured) ...[
                const SizedBox(height: AppSpacing.s6),
                _LegalAcceptance(
                  termsAccepted: _termsAccepted,
                  privacyAccepted: _privacyAccepted,
                  termsVersion: state.legalConfig.termsVersion!,
                  privacyVersion: state.legalConfig.privacyVersion!,
                  onTermsChanged: state.isBusy
                      ? null
                      : (value) =>
                            setState(() => _termsAccepted = value ?? false),
                  onPrivacyChanged: state.isBusy
                      ? null
                      : (value) =>
                            setState(() => _privacyAccepted = value ?? false),
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
                const SizedBox(height: AppSpacing.s4),
                Notice(
                  key: const ValueKey('registration-error'),
                  tone: NoticeTone.error,
                  icon: Icons.error_outline_rounded,
                  live: true,
                  message: state.message!,
                  action:
                      state.failureKind ==
                          RegistrationFailureKind.cpfAlreadyRegistered
                      ? TextButton(
                          key: const ValueKey('duplicate-cpf-login'),
                          onPressed: _goToLogin,
                          child: const Text('Ir para o login'),
                        )
                      : null,
                ),
              ],
              const SizedBox(height: AppSpacing.s6),
              PrimaryButton(
                key: const ValueKey('registration-submit'),
                label: 'CRIAR CONTA',
                loadingLabel: 'CRIANDO CONTA',
                loading: state.isBusy,
                onPressed: _canSubmit(state) ? _submit : null,
              ),
              const SizedBox(height: AppSpacing.s2),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Já tem conta?',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.semantic.muted,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('registration-login'),
                    onPressed: state.isBusy ? null : _goToLogin,
                    child: const Text('Entrar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Cadastrar-se no app não identifica uma compra no Terminal.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ),
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
  Widget build(BuildContext context) => Column(
    key: const ValueKey('legal-acceptance'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'TERMOS E PRIVACIDADE',
        style: context.eyebrowStyle.copyWith(color: context.semantic.muted),
      ),
      const SizedBox(height: AppSpacing.s1),
      ListGroup(
        children: [
          _LegalCheck(
            key: const ValueKey('accept-terms'),
            value: termsAccepted,
            onChanged: onTermsChanged,
            title: 'Li e aceito os Termos de Uso.',
            linkLabel: 'Ler Termos — versão $termsVersion',
            onOpen: onOpenTerms,
          ),
          _LegalCheck(
            key: const ValueKey('accept-privacy'),
            value: privacyAccepted,
            onChanged: onPrivacyChanged,
            title: 'Li e aceito a Política de Privacidade.',
            linkLabel: 'Ler Política — versão $privacyVersion',
            onOpen: onOpenPrivacy,
          ),
        ],
      ),
    ],
  );
}

class _LegalCheck extends StatelessWidget {
  const _LegalCheck({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.linkLabel,
    required this.onOpen,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title, linkLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: value,
    onChanged: onChanged,
    title: Text(title, style: context.text.titleSmall),
    subtitle: Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        link: true,
        child: TextButton(
          onPressed: onOpen,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 40),
            alignment: Alignment.centerLeft,
          ),
          child: Text(
            linkLabel,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ),
    ),
  );
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: AppContent(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.s10,
        AppSpacing.gutter,
        AppSpacing.s8,
      ),
      child: Column(
        key: const ValueKey('registration-success'),
        children: [
          Semantics(
            liveRegion: true,
            label: 'Cadastro concluído',
            child: ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.semantic.successContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: context.semantic.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            'Cadastro concluído',
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Sua conta foi criada. Entre com seu CPF e senha para continuar.',
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.semantic.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          PrimaryButton(
            key: const ValueKey('success-login'),
            label: 'IR PARA O LOGIN',
            icon: Icons.arrow_forward_rounded,
            onPressed: onLogin,
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
