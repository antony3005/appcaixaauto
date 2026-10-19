import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/client_repository.dart';
import '../../domain/models.dart';
import '../../shared/app_widgets.dart';

class TemporaryQrPage extends StatefulWidget {
  const TemporaryQrPage._({
    required this.repository,
    required this.session,
    required this.title,
    required this.instruction,
    required this.loadToken,
    this.benefit,
    this.benefitDetail,
  });

  factory TemporaryQrPage.coupon({
    required ClientRepository repository,
    required AuthSession session,
    required CouponSummary coupon,
  }) => TemporaryQrPage._(
    repository: repository,
    session: session,
    title: 'Use no Terminal',
    benefit: coupon.title,
    benefitDetail: 'Compra mínima: ${money(coupon.minimumPurchase)}',
    instruction: 'Mostre este QR ao leitor do Terminal antes de pagar.',
    loadToken: () => repository.createCouponToken(session, coupon.id),
  );

  final ClientRepository repository;
  final AuthSession session;
  final String title, instruction;
  final String? benefit, benefitDetail;
  final Future<TemporaryQrToken> Function() loadToken;

  @override
  State<TemporaryQrPage> createState() => _TemporaryQrPageState();
}

class _TemporaryQrPageState extends State<TemporaryQrPage> {
  TemporaryQrToken? token;
  String? error;
  bool loading = false;
  Timer? timer;
  Duration clockOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    generate();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool get expired =>
      token == null ||
      !token!.expiresAt.isAfter(DateTime.now().add(clockOffset));
  Duration get remaining => token == null
      ? Duration.zero
      : token!.expiresAt.difference(DateTime.now().add(clockOffset));

  Future<void> generate() async {
    if (loading) return;
    timer?.cancel();
    setState(() {
      loading = true;
      error = null;
      token = null;
    });
    try {
      final result = await widget.loadToken();
      if (!mounted) return;
      setState(() {
        token = result;
        clockOffset = result.serverTime == null
            ? Duration.zero
            : result.serverTime!.difference(DateTime.now());
      });
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (expired) {
          timer?.cancel();
        }
      });
    } on AppException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Não foi possível gerar o código. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = token != null && !expired;
    return Scaffold(
      appBar: AppTopBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: AppContent(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.s2,
              AppSpacing.gutter,
              AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.benefit != null) ...[
                  Notice(
                    tone: NoticeTone.gold,
                    icon: Icons.confirmation_number_outlined,
                    title: widget.benefit,
                    message: widget.benefitDetail ?? '',
                  ),
                  const SizedBox(height: AppSpacing.s5),
                ],
                Text(
                  widget.instruction,
                  textAlign: TextAlign.center,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Center(
                  child: Container(
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
                          dimension: 220,
                          child: Center(child: _qrContent(context)),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _status(context),
                      ],
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Notice(
                    tone: NoticeTone.error,
                    icon: Icons.error_outline_rounded,
                    message: error!,
                    live: true,
                  ),
                ],
                if (!loading && !valid) ...[
                  const SizedBox(height: AppSpacing.s6),
                  PrimaryButton(
                    navy: true,
                    label: 'GERAR NOVO CÓDIGO',
                    icon: Icons.refresh_rounded,
                    onPressed: generate,
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                const Notice(
                  icon: Icons.shield_outlined,
                  message:
                      'O código é temporário e validado pelo servidor. Ele não contém seu CPF, senha ou saldo.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _status(BuildContext context) {
    const muted = Color(0xFF607389);
    const ink = Color(0xFF10243B);
    final base = context.text.bodySmall?.copyWith(
      color: muted,
      fontWeight: FontWeight.w600,
    );
    final (Widget text, Color dot) = loading
        ? (Text('Gerando código...', style: base), muted)
        : token != null && !expired
        ? (
            Text.rich(
              TextSpan(
                text: 'Expira em ',
                children: [
                  TextSpan(
                    text: _countdown(remaining),
                    style: context.text.titleMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              style: base,
            ),
            const Color(0xFFE8860C),
          )
        : token != null
        ? (
            Text(
              'Código expirado',
              style: base?.copyWith(color: const Color(0xFFBA1A1A)),
            ),
            const Color(0xFFBA1A1A),
          )
        : (Text('Código indisponível', style: base), muted);
    return Semantics(
      liveRegion: true,
      child: Row(
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

  Widget _qrContent(BuildContext context) {
    if (loading) {
      return const SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.navy,
          backgroundColor: Color(0xFFEEF3F8),
        ),
      );
    }
    if (token != null && !expired) {
      return Semantics(
        label: 'QR Code temporário para apresentar ao leitor do Terminal',
        image: true,
        child: QrImageView(
          data: token!.value,
          version: QrVersions.auto,
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
    return ExcludeSemantics(
      child: Icon(
        error == null ? Icons.timer_off_outlined : Icons.qr_code_2_rounded,
        size: 72,
        color: error == null
            ? const Color(0xFFBA1A1A)
            : const Color(0xFF607389),
      ),
    );
  }

  String _countdown(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 5999);
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
