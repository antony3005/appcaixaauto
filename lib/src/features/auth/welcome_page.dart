import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/app_widgets.dart';

/// Boas-vindas: o que o app faz em três linhas antes de pedir qualquer dado.
class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.onStart, required this.onLogin, super.key});
  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
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
                const SizedBox(height: AppSpacing.s6),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.all(AppSpacing.s3),
                    decoration: BoxDecoration(
                      color: AppColors.qrPaper,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Image.asset(
                        'lib/src/content/app_logo.png',
                        semanticLabel: '24/7 Serviços',
                        fit: BoxFit.contain,
                      ),
                    ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Seu condomínio, mais inteligente todo dia.',
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  const AppListRow(
                    leading: IconWell(icon: Icons.qr_code_2_rounded),
                    title: 'Identifique-se no Terminal',
                    subtitle: 'Seu QR pessoal, sempre à mão.',
                  ),
                  const AppListRow(
                    leading: IconWell(icon: Icons.receipt_long_rounded),
                    title: 'Compras e comprovantes',
                    subtitle: 'Histórico do seu condomínio.',
                  ),
                  const AppListRow(
                    leading: IconWell(
                      icon: Icons.star_rounded,
                      tone: WellTone.gold,
                    ),
                    title: 'Pontos e recompensas',
                    subtitle: 'Cada compra identificada vale benefícios.',
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  PrimaryButton(
                    key: const ValueKey('welcome-start'),
                    label: 'COMEÇAR',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onStart,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem conta?',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.semantic.muted,
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('welcome-login'),
                        onPressed: onLogin,
                        child: const Text('Entrar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
