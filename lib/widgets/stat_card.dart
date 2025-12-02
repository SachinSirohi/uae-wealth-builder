import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class StatCard extends StatelessWidget {
  final String title;
  final double value;
  final String currency;
  final Color color;
  final String? subtitle;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.currency,
    required this.color,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppConstants.spacingS),
            ],
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              '$currency ${currencyFormat.format(value)}',
              style: AppTextStyles.numberLarge.copyWith(
                fontSize: 22,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTextStyles.label.copyWith(
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
