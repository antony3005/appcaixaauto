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
      return Scaffold(
        appBar: AppBar(title: const Text('Recuperar senha')),
        body: SafeArea(
          top: false,
          child: AppContent(
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  _StepIndicator(step: state.step),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedSwitcher(
                    duration: AppAnimations.medium,
                    switchInCurve: AppAnimations.emphasized,
                    child: _content(state),
                  ),
                  if (state.message != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InlineMessage(
                      icon: Icons.mark_email_read_outlined,
                      message: state.message!,
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        state.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (state.step != PasswordRecoveryStep.success)
                    FilledButton(
                      key: const ValueKey('password-recovery-submit'),
                      onPressed: state.busy ? null : submit,
                      child: state.busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_buttonLabel(state.step)),
                    ),
                  if (state.step == PasswordRecoveryStep.code) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: state.busy ? null : controller.restart,
                      child: const Text('Usar outro CPF'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _content(PasswordRecoveryState state) => switch (state.step) {
    PasswordRecoveryStep.request => Column(
      key: const ValueKey('recovery-request'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vamos localizar sua conta', style: _title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Informe seu CPF. Por segurança, a resposta será a mesma mesmo que a conta não exista.',
          style: _body,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: cpf,
          inputFormatters: <TextInputFormatter>[cpfMask],
          keyboardType: TextInputType.number,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Digite o código', style: _title),
        const SizedBox(height: AppSpacing.xs),
        Text('Use o código recebido no e-mail cadastrado.', style: _body),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: code,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(
            labelText: 'Código de verificação',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crie uma nova senha', style: _title),
        const SizedBox(height: AppSpacing.xs),
        Text('Use entre 8 e 100 caracteres.', style: _body),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: password,
          obscureText: obscure,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () => setState(() => obscure = !obscure),
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: confirmation,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          decoration: const InputDecoration(
            labelText: 'Confirmar nova senha',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
          validator: (value) =>
              value == password.text ? null : 'As senhas precisam ser iguais.',
        ),
      ],
    ),
    PasswordRecoveryStep.success => Column(
      key: const ValueKey('recovery-success'),
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 72,
          color: context.semantic.success,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Senha redefinida', style: _title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Você já pode entrar usando a nova senha.',
          style: _body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar ao login'),
          ),
        ),
      ],
    ),
  };

  TextStyle? get _title => Theme.of(context).textTheme.headlineSmall;
  TextStyle? get _body => Theme.of(
    context,
  ).textTheme.bodyLarge?.copyWith(color: context.semantic.muted);
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final PasswordRecoveryStep step;

  @override
  Widget build(BuildContext context) {
    final index = PasswordRecoveryStep.values.indexOf(step).clamp(0, 2);
    return Semantics(
      label: 'Etapa ${index + 1} de 3',
      child: Row(
        children: List.generate(
          3,
          (item) => Expanded(
            child: AnimatedContainer(
              duration: AppAnimations.short,
              height: 4,
              margin: EdgeInsets.only(right: item == 2 ? 0 : AppSpacing.xs),
              decoration: BoxDecoration(
                color: item <= index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

String _buttonLabel(PasswordRecoveryStep step) => switch (step) {
  PasswordRecoveryStep.request => 'Enviar código',
  PasswordRecoveryStep.code => 'Validar código',
  PasswordRecoveryStep.newPassword => 'Redefinir senha',
  PasswordRecoveryStep.success => 'Voltar ao login',
};
