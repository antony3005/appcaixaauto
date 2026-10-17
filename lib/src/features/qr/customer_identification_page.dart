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
    appBar: AppBar(title: const Text('Meu QR')),
    body: SafeArea(
      child: AppContent(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = math
                  .min(288.0, constraints.maxWidth - 64)
                  .clamp(200.0, 288.0)
                  .toDouble();
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(AppRadii.hero),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: AppColors.darkText,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'IDENTIFICAÇÃO APP247',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.darkText),
                                ),
                              ),
                              Icon(
                                Icons.shield_rounded,
                                size: 20,
                                color: context.semantic.gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _QrSurface(controller: controller, size: qrSize),
                          const SizedBox(height: AppSpacing.md),
                          _Status(controller: controller),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Use este código no Terminal antes de finalizar sua compra.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _benefitMessage(widget.loyaltyMode),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.semantic.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('customer-qr-generate'),
                        onPressed: controller.isLoading
                            ? null
                            : controller.generate,
                        icon: Icon(
                          controller.hasValidQr
                              ? Icons.refresh_rounded
                              : Icons.qr_code_2_rounded,
                        ),
                        label: Text(
                          controller.phase ==
                                      CustomerIdentificationPhase.error ||
                                  controller.phase ==
                                      CustomerIdentificationPhase.offline
                              ? 'TENTAR NOVAMENTE'
                              : 'GERAR NOVO QR',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      container: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Não compartilhe este QR. Ele é temporário e serve somente para vincular sua compra.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _QrSurface extends StatelessWidget {
  const _QrSurface({required this.controller, required this.size});

  final CustomerIdentificationController controller;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size + 32,
    height: size + 32,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.qrPaper,
      borderRadius: BorderRadius.circular(AppRadii.card),
      border: Border.all(color: AppColors.line),
    ),
    child: Center(child: _content(context)),
  );

  Widget _content(BuildContext context) {
    if (controller.isLoading) {
      return Semantics(
        liveRegion: true,
        label: 'Gerando seu QR',
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Gerando seu QR...'),
          ],
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
          padding: const EdgeInsets.all(AppSpacing.xs),
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
    return Icon(
      controller.phase == CustomerIdentificationPhase.expired
          ? Icons.timer_off_outlined
          : Icons.qr_code_2_rounded,
      size: 72,
      color: controller.phase == CustomerIdentificationPhase.expired
          ? AppColors.coral
          : AppColors.muted,
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.controller});
  final CustomerIdentificationController controller;

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = switch (controller.phase) {
      CustomerIdentificationPhase.initial ||
      CustomerIdentificationPhase.loading => (
        'Gerando seu QR...',
        AppColors.muted,
        Icons.hourglass_top_rounded,
      ),
      CustomerIdentificationPhase.valid => (
        'Expira em ${_countdown(controller.remaining)}',
        AppColors.fresh,
        Icons.timer_outlined,
      ),
      CustomerIdentificationPhase.expired => (
        'QR expirado',
        AppColors.coral,
        Icons.timer_off_outlined,
      ),
      CustomerIdentificationPhase.offline ||
      CustomerIdentificationPhase.error => (
        controller.errorMessage ?? 'Não foi possível gerar seu QR.',
        Theme.of(context).colorScheme.error,
        Icons.error_outline_rounded,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('customer-qr-status'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.qrPaper,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
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
