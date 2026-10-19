import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';
import '../../state/customer_identification_controller.dart';

class CustomerIdentificationPage extends StatefulWidget {
  const CustomerIdentificationPage({
    required this.repository,
    required this.session,
    required this.loyaltyMode,
    super.key,
    this.controller,
  });

  final ClientRepository repository;
  final AuthSession session;
  final LoyaltyMode loyaltyMode;
  final CustomerIdentificationController? controller;

  @override
  State<CustomerIdentificationPage> createState() =>
      _CustomerIdentificationPageState();
}

class _CustomerIdentificationPageState extends State<CustomerIdentificationPage>
    with WidgetsBindingObserver {
  late final CustomerIdentificationController controller =
      widget.controller ??
      CustomerIdentificationController(
        repository: widget.repository,
        session: widget.session,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (controller.phase == CustomerIdentificationPhase.initial) {
      controller.generate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refreshForCurrentTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final qrSize = math
              .min(240.0, constraints.maxWidth - 120)
              .clamp(180.0, 240.0)
              .toDouble();
          final canPop = Navigator.of(context).canPop();
          final failed =
              controller.phase == CustomerIdentificationPhase.error ||
              controller.phase == CustomerIdentificationPhase.offline;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandHeader(
                  padding: EdgeInsets.fromLTRB(
                    canPop ? AppSpacing.s3 : AppSpacing.gutter,
                    AppSpacing.s3,
                    AppSpacing.gutter,
                    AppSpacing.s6,
                  ),
                  child: Row(
                    children: [
                      if (canPop) ...[
                        const BackButton(color: AppColors.onNavy),
                        const SizedBox(width: AppSpacing.s1),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Meu QR',
                                style: context.text.titleLarge?.copyWith(
                                  color: AppColors.onNavy,
                                ),
                              ),
                            ),
                            Text(
                              'Identificação segura no Terminal',
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.onNavyMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ExcludeSemantics(
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: context.semantic.gold,
                          size: AppSizes.iconLg,
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
                      AppSpacing.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Mostre este QR no Terminal antes de finalizar sua compra.',
                          textAlign: TextAlign.center,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Center(
                          child: _QrCard(controller: controller, size: qrSize),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          _benefitMessage(widget.loyaltyMode),
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        PrimaryButton(
                          key: const ValueKey('customer-qr-generate'),
                          navy: true,
                          label: failed ? 'TENTAR NOVAMENTE' : 'GERAR NOVO QR',
                          icon: failed
                              ? Icons.refresh_rounded
                              : Icons.qr_code_2_rounded,
                          onPressed: controller.isLoading
                              ? null
                              : controller.generate,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        const Notice(
                          icon: Icons.shield_outlined,
                          message:
                              'Não compartilhe este QR. Ele é temporário e serve somente para vincular sua compra.',
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        const Notice(message: terminalReminder),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// O QR em papel branco: módulos escuros em qualquer tema.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.controller, required this.size});

  final CustomerIdentificationController controller;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size + AppSpacing.s5 * 2,
    padding: const EdgeInsets.all(AppSpacing.s5),
    decoration: BoxDecoration(
      color: AppColors.qrPaper,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      boxShadow: context.semantic.raisedShadow,
      border: Border.all(color: context.colors.outline),
    ),
    child: Column(
      children: [
        SizedBox.square(
          dimension: size,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppAnimations.medium,
              child: _content(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        _Status(controller: controller),
      ],
    ),
  );

  Widget _content(BuildContext context) {
    if (controller.isLoading) {
      return Semantics(
        key: const ValueKey('qr-loading'),
        liveRegion: true,
        label: 'Gerando seu QR',
        child: const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.navy,
            backgroundColor: Color(0xFFEEF3F8),
          ),
        ),
      );
    }
    final token = controller.token;
    if (controller.hasValidQr && token != null) {
      return Semantics(
        image: true,
        label: 'QR temporário para apresentar ao scanner do Terminal App247',
        child: QrImageView(
          key: const ValueKey('customer-identification-qr'),
          data: token.qrPayload,
          version: QrVersions.auto,
          size: size,
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.qrPaper,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: AppColors.qrInk,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppColors.qrInk,
          ),
        ),
      );
    }
    final expired = controller.phase == CustomerIdentificationPhase.expired;
    return ExcludeSemantics(
      key: ValueKey(controller.phase),
      child: Icon(
        expired ? Icons.timer_off_outlined : Icons.qr_code_2_rounded,
        size: 72,
        color: expired ? const Color(0xFFBA1A1A) : const Color(0xFF607389),
      ),
    );
  }
}

/// Contador sob o QR. Fica sempre sobre o papel branco, então usa as
/// cores do tema claro nos dois temas.
class _Status extends StatelessWidget {
  const _Status({required this.controller});
  final CustomerIdentificationController controller;

  static const _ink = Color(0xFF10243B);
  static const _muted = Color(0xFF607389);
  static const _amber = Color(0xFFE8860C);
  static const _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    final base = context.text.bodySmall?.copyWith(
      color: _muted,
      fontWeight: FontWeight.w600,
    );
    final strong = context.text.titleMedium?.copyWith(
      color: _ink,
      fontWeight: FontWeight.w800,
    );
    final (Widget text, Color dot) = switch (controller.phase) {
      CustomerIdentificationPhase.initial ||
      CustomerIdentificationPhase.loading => (
        Text('Gerando seu QR...', style: base),
        _muted,
      ),
      CustomerIdentificationPhase.valid => (
        Text.rich(
          TextSpan(
            text: 'Expira em ',
            children: [
              TextSpan(text: _countdown(controller.remaining), style: strong),
            ],
          ),
          style: base,
        ),
        _amber,
      ),
      CustomerIdentificationPhase.expired => (
        Text('QR expirado', style: base?.copyWith(color: _error)),
        _error,
      ),
      CustomerIdentificationPhase.offline ||
      CustomerIdentificationPhase.error => (
        Text(
          controller.errorMessage ?? 'Não foi possível gerar seu QR.',
          textAlign: TextAlign.center,
          style: base?.copyWith(color: _error),
        ),
        _error,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        key: const ValueKey('customer-qr-status'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(child: text),
        ],
      ),
    );
  }
}

String _benefitMessage(LoyaltyMode mode) => switch (mode) {
  LoyaltyMode.points => 'Vincule a compra para acumular pontos.',
  LoyaltyMode.cashback =>
    'Vincule a compra para receber cashback quando aplicável.',
  LoyaltyMode.none => 'Vincule para salvar a compra no seu histórico.',
};

String _countdown(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 5999);
  return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
