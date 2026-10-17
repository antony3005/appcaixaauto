import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final vertical = largeText && MediaQuery.sizeOf(context).width < 400;
    final logo = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Center(
        child: Text(
          '24/7',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.darkText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APP 24/7',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          'CLIENTE',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.semantic.success,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          logo,
          const SizedBox(height: AppSpacing.sm),
          labels,
        ],
      );
    }
    return Row(
      children: [
        logo,
        const SizedBox(width: AppSpacing.sm),
        labels,
      ],
    );
  }
}
