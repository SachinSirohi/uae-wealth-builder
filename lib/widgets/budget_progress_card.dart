import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class BudgetProgressCard extends StatelessWidget {
  final String title;
  final double currentValue;
  final double targetValue;
  final double percentage;
  final double targetPercentage;
  final String currency;
  final Color color;

  const BudgetProgressCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.percentage,
    required this.targetPercentage,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0');
    final percentageFormat = NumberFormat('0%');
    final isOnTrack = percentage >= targetPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    percentageFormat.format(percentage),
                    style: AppTextStyles.heading3.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${currencyFormat.format(currentValue)}',
                      style: AppTextStyles.numberMedium.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${currencyFormat.format(targetValue)}',
                      style: AppTextStyles.numberMedium.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Status Message
            if (!isOnTrack) ...[
              const SizedBox(height: AppConstants.spacingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        'Need ${percentageFormat.format(targetPercentage - percentage)} more to meet target',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
