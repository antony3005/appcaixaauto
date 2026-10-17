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
  });

  factory TemporaryQrPage.coupon({
    required ClientRepository repository,
    required AuthSession session,
    required CouponSummary coupon,
  }) => TemporaryQrPage._(
    repository: repository,
    session: session,
    title: 'Use no Terminal',
    benefit: '${coupon.title}\nCompra mínima: ${money(coupon.minimumPurchase)}',
    instruction: 'Mostre este QR Code ao leitor do Terminal.',
    loadToken: () => repository.createCouponToken(session, coupon.id),
  );

  final ClientRepository repository;
  final AuthSession session;
  final String title, instruction;
  final String? benefit;
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: AppContent(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.benefit != null) ...[
                Text(
                  widget.benefit!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                widget.instruction,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox.square(
                    dimension: 250,
                    child: Center(child: _qrContent(context)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (token != null && !expired)
                Semantics(
                  liveRegion: true,
                  label: 'Código expira em ${_countdown(remaining)}',
                  child: Text(
                    'Expira em ${_countdown(remaining)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.fresh),
                  ),
                ),
              if (token != null && expired)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Código expirado',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.coral),
                  ),
                ),
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (!loading && (expired || error != null))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: generate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Gerar novo código'),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'O código é temporário, opaco e validado pelo backend. Ele não contém seu CPF, senha ou saldo.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _qrContent(BuildContext context) {
    if (loading) {
      return const CircularProgressIndicator();
    }
    if (token != null && !expired) {
      return Semantics(
        label: 'QR Code temporário para apresentar ao leitor do Terminal',
        image: true,
        child: QrImageView(
          data: token!.value,
          version: QrVersions.auto,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: AppColors.navyDark,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppColors.navyDark,
          ),
        ),
      );
    }
    return Icon(
      error == null ? Icons.timer_off_outlined : Icons.qr_code_2_rounded,
      size: 72,
      color: error == null ? AppColors.coral : AppColors.muted,
    );
  }

  String _countdown(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 5999);
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
