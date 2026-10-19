import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../shared/app_widgets.dart';
import '../../state/password_recovery_controller.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({required this.repository, super.key});
  final ClientRepository repository;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final PasswordRecoveryController controller = PasswordRecoveryController(
    widget.repository,
  );
  final formKey = GlobalKey<FormState>();
  final cpf = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  bool obscure = true;

  @override
  void dispose() {
    controller.dispose();
    cpf.dispose();
    code.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    switch (controller.state.step) {
      case PasswordRecoveryStep.request:
        await controller.requestCode(cpfMask.getUnmaskedText());
      case PasswordRecoveryStep.code:
        await controller.validateCode(code.text.trim());
      case PasswordRecoveryStep.newPassword:
        await controller.resetPassword(password.text);
      case PasswordRecoveryStep.success:
        if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final state = controller.state;
      final done = state.step == PasswordRecoveryStep.success;
      return Scaffold(
        appBar: const AppTopBar(title: 'Recuperar senha', showBack: true),
        body: SafeArea(
          top: false,
          child: Form(
            key: formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      if (!done) ...[
                        _StepIndicator(step: state.step),
                        const SizedBox(height: AppSpacing.s8),
                      ],
                      AnimatedSwitcher(
                        duration: AppAnimations.medium,
                        switchInCurve: AppAnimations.emphasized,
                        switchOutCurve: AppAnimations.exit,
                        child: _content(state),
                      ),
                      if (state.message != null) ...[
                        const SizedBox(height: AppSpacing.s5),
                        Notice(
                          icon: Icons.mark_email_read_outlined,
                          message: state.message!,
                          live: true,
                        ),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: AppSpacing.s5),
                        Notice(
                          tone: NoticeTone.error,
                          icon: Icons.error_outline_rounded,
                          message: state.error!,
                          live: true,
                        ),
                      ],
                      if (!done) ...[
                        const SizedBox(height: AppSpacing.s6),
                        PrimaryButton(
                          key: const ValueKey('password-recovery-submit'),
                          label: _buttonLabel(state.step),
                          loading: state.busy,
                          onPressed: submit,
                        ),
                      ],
                      if (state.step == PasswordRecoveryStep.code) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Center(
                          child: TextButton(
                            onPressed: state.busy ? null : controller.restart,
                            child: const Text('Usar outro CPF'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _content(PasswordRecoveryState state) => switch (state.step) {
    PasswordRecoveryStep.request => Column(
      key: const ValueKey('recovery-request'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vamos localizar sua conta', style: _title),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'Informe seu CPF. Por segurança, a resposta será a mesma mesmo que a conta não exista.',
          style: _body,
        ),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: cpf,
          inputFormatters: <TextInputFormatter>[cpfMask],
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'CPF',
            hintText: '000.000.000-00',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (_) => cpfMask.getUnmaskedText().length == 11
              ? null
              : 'Informe um CPF com 11 números.',
        ),
      ],
    ),
    PasswordRecoveryStep.code => Column(
      key: const ValueKey('recovery-code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Digite o código', style: _title),
        const SizedBox(height: AppSpacing.s2),
        Text('Use o código recebido no e-mail cadastrado.', style: _body),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: code,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(
            labelText: 'Código de verificação',
            hintText: 'Somente números',
            prefixIcon: Icon(Icons.password_rounded),
          ),
          validator: (value) => (value?.trim().isNotEmpty ?? false)
              ? null
              : 'Informe o código recebido.',
        ),
      ],
    ),
    PasswordRecoveryStep.newPassword => Column(
      key: const ValueKey('recovery-password'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Crie uma nova senha', style: _title),
        const SizedBox(height: AppSpacing.s2),
        Text('Use entre 8 e 100 caracteres.', style: _body),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: password,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'Nova senha',
            hintText: 'Entre 8 e 100 caracteres',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () => setState(() => obscure = !obscure),
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: AppSizes.iconMd,
              ),
            ),
          ),
          validator: (value) {
            final length = value?.length ?? 0;
            return length >= 8 && length <= 100
                ? null
                : 'A senha deve ter entre 8 e 100 caracteres.';
          },
        ),
        const SizedBox(height: AppSpacing.s5),
        TextFormField(
          controller: confirmation,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          decoration: const InputDecoration(
            labelText: 'Confirmar nova senha',
            hintText: 'Repita a nova senha',
            prefixIcon: Icon(Icons.lock_reset_rounded),
          ),
          validator: (value) =>
              value == password.text ? null : 'As senhas precisam ser iguais.',
        ),
      ],
    ),
    PasswordRecoveryStep.success => Column(
      key: const ValueKey('recovery-success'),
      children: [
        const SizedBox(height: AppSpacing.s8),
        ExcludeSemantics(
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
        const SizedBox(height: AppSpacing.s6),
        Semantics(
          liveRegion: true,
          child: Text(
            'Senha redefinida',
            style: _title,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'Você já pode entrar usando a nova senha.',
          style: _body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        PrimaryButton(
          label: 'VOLTAR AO LOGIN',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  };

  TextStyle? get _title => context.text.headlineSmall;
  TextStyle? get _body =>
      context.text.bodyMedium?.copyWith(color: context.semantic.muted);
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final PasswordRecoveryStep step;

  @override
  Widget build(BuildContext context) {
    final index = PasswordRecoveryStep.values.indexOf(step).clamp(0, 2);
    return Semantics(
      label: 'Etapa ${index + 1} de 3',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ETAPA ${index + 1} DE 3',
            style: context.eyebrowStyle.copyWith(color: context.semantic.muted),
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: List.generate(
              3,
              (item) => Expanded(
                child: AnimatedContainer(
                  duration: AppAnimations.medium,
                  curve: AppAnimations.standard,
                  height: 4,
                  margin: EdgeInsets.only(right: item == 2 ? 0 : AppSpacing.s2),
                  decoration: BoxDecoration(
                    color: item <= index
                        ? context.colors.primary
                        : context.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _buttonLabel(PasswordRecoveryStep step) => switch (step) {
  PasswordRecoveryStep.request => 'ENVIAR CÓDIGO',
  PasswordRecoveryStep.code => 'VALIDAR CÓDIGO',
  PasswordRecoveryStep.newPassword => 'REDEFINIR SENHA',
  PasswordRecoveryStep.success => 'VOLTAR AO LOGIN',
};
