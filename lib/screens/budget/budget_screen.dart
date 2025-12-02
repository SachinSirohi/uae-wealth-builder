import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../models/user_settings.dart';
import '../../services/database_service.dart';

class BudgetScreen extends StatefulWidget {
  final double monthlySalary;
  final String currency;

  const BudgetScreen({
    super.key,
    required this.monthlySalary,
    required this.currency,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  // Budget Allocations (40/20/40 default)
  double _needsPercentage = 0.40;
  double _wantsPercentage = 0.20;
  double _savingsPercentage = 0.40;

  // Actual Spending
  Map<TransactionCategory, double> _spendingByCategory = {};
  double _totalNeeds = 0;
  double _totalWants = 0;
  double _totalSavings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    final spending = _databaseService.getSpendingByCategory(now);

    setState(() {
      _spendingByCategory = spending;
      _totalNeeds = 0;
      _totalWants = 0;
      _totalSavings = 0;

      spending.forEach((category, amount) {
        switch (category.budgetType) {
          case BudgetType.needs:
            _totalNeeds += amount;
            break;
          case BudgetType.wants:
            _totalWants += amount;
            break;
          case BudgetType.savings:
            _totalSavings += amount;
            break;
        }
      });
    });
  }

  double get _needsBudget => widget.monthlySalary * _needsPercentage;
  double get _wantsBudget => widget.monthlySalary * _wantsPercentage;
  double get _savingsBudget => widget.monthlySalary * _savingsPercentage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Allocation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBudget,
            tooltip: 'Save Budget',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Monthly Income Display
            _buildIncomeCard(),
            const SizedBox(height: AppConstants.spacingL),

            // Budget Allocation Sliders
            _buildAllocationSection(),
            const SizedBox(height: AppConstants.spacingL),

            // Envelope System
            _buildEnvelopeSection(),
            const SizedBox(height: AppConstants.spacingL),

            // Budget vs Actual
            _buildBudgetVsActualSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard() {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            Text(
              'Monthly Income',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              '${widget.currency} ${_currencyFormat.format(widget.monthlySalary)}',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget Allocation', style: AppTextStyles.heading2),
                TextButton(
                  onPressed: _resetToDefault,
                  child: const Text('Reset to 40/20/40'),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Needs Slider
            _buildAllocationSlider(
              label: 'Needs',
              value: _needsPercentage,
              color: AppColors.needsColor,
              onChanged: (value) {
                setState(() {
                  _needsPercentage = value;
                  _balanceBudget('needs');
                });
              },
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Wants Slider
            _buildAllocationSlider(
              label: 'Wants',
              value: _wantsPercentage,
              color: AppColors.wantsColor,
              onChanged: (value) {
                setState(() {
                  _wantsPercentage = value;
                  _balanceBudget('wants');
                });
              },
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Savings Slider
            _buildAllocationSlider(
              label: 'Savings',
              value: _savingsPercentage,
              color: AppColors.savingsColor,
              onChanged: (value) {
                setState(() {
                  _savingsPercentage = value;
                  _balanceBudget('savings');
                });
              },
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Visual Breakdown Bar
            _buildBreakdownBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyLarge),
            Text(
              '${(value * 100).toStringAsFixed(0)}% - ${widget.currency} ${_currencyFormat.format(widget.monthlySalary * value)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            inactiveTrackColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 0.05,
            max: 0.70,
            divisions: 65,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Allocation', style: AppTextStyles.label),
        const SizedBox(height: AppConstants.spacingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          child: Row(
            children: [
              Expanded(
                flex: (_needsPercentage * 100).toInt(),
                child: Container(
                  height: 24,
                  color: AppColors.needsColor,
                  alignment: Alignment.center,
                  child: Text(
                    '${(_needsPercentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: (_wantsPercentage * 100).toInt(),
                child: Container(
                  height: 24,
                  color: AppColors.wantsColor,
                  alignment: Alignment.center,
                  child: Text(
                    '${(_wantsPercentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: (_savingsPercentage * 100).toInt(),
                child: Container(
                  height: 24,
                  color: AppColors.savingsColor,
                  alignment: Alignment.center,
                  child: Text(
                    '${(_savingsPercentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnvelopeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Envelope System', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacingM),

            // Needs Envelopes
            _buildEnvelopeGroup(
              title: 'Needs',
              color: AppColors.needsColor,
              totalBudget: _needsBudget,
              categories: [
                TransactionCategory.housing,
                TransactionCategory.groceries,
                TransactionCategory.utilities,
                TransactionCategory.transport,
                TransactionCategory.medical,
                TransactionCategory.insurance,
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Wants Envelopes
            _buildEnvelopeGroup(
              title: 'Wants',
              color: AppColors.wantsColor,
              totalBudget: _wantsBudget,
              categories: [
                TransactionCategory.dining,
                TransactionCategory.entertainment,
                TransactionCategory.shopping,
                TransactionCategory.subscriptions,
                TransactionCategory.travel,
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Savings Envelopes
            _buildEnvelopeGroup(
              title: 'Savings',
              color: AppColors.savingsColor,
              totalBudget: _savingsBudget,
              categories: [
                TransactionCategory.investments,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvelopeGroup({
    required String title,
    required Color color,
    required double totalBudget,
    required List<TransactionCategory> categories,
  }) {
    final categoryBudget = totalBudget / categories.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(color: color),
            ),
            Text(
              '${widget.currency} ${_currencyFormat.format(totalBudget)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: categories.map((category) {
            final spent = _spendingByCategory[category] ?? 0;
            final percentage = categoryBudget > 0 ? spent / categoryBudget : 0.0;

            return _buildEnvelopeCard(
              category: category,
              budget: categoryBudget,
              spent: spent,
              percentage: percentage,
              color: color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEnvelopeCard({
    required TransactionCategory category,
    required double budget,
    required double spent,
    required double percentage,
    required Color color,
  }) {
    final isOverspent = percentage > 1.0;
    final remaining = budget - spent;

    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 2,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isOverspent ? AppColors.danger : color.withOpacity(0.3),
          width: isOverspent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _getCategoryIcon(category),
                color: color,
                size: 20,
              ),
              if (isOverspent)
                const Icon(
                  Icons.warning,
                  color: AppColors.danger,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            category.displayName,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            '${widget.currency} ${_currencyFormat.format(spent)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isOverspent ? AppColors.danger : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'of ${widget.currency} ${_currencyFormat.format(budget)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverspent ? AppColors.danger : color,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            isOverspent
                ? 'Over by ${widget.currency} ${_currencyFormat.format(-remaining)}'
                : 'Left: ${widget.currency} ${_currencyFormat.format(remaining)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isOverspent ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetVsActualSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget vs Actual', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacingL),

            _buildBudgetVsActualRow(
              label: 'Needs',
              budget: _needsBudget,
              actual: _totalNeeds,
              color: AppColors.needsColor,
            ),
            const SizedBox(height: AppConstants.spacingM),

            _buildBudgetVsActualRow(
              label: 'Wants',
              budget: _wantsBudget,
              actual: _totalWants,
              color: AppColors.wantsColor,
            ),
            const SizedBox(height: AppConstants.spacingM),

            _buildBudgetVsActualRow(
              label: 'Savings',
              budget: _savingsBudget,
              actual: _totalSavings,
              color: AppColors.savingsColor,
            ),
            const Divider(height: AppConstants.spacingL * 2),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Spent', style: AppTextStyles.heading3),
                Text(
                  '${widget.currency} ${_currencyFormat.format(_totalNeeds + _totalWants + _totalSavings)}',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetVsActualRow({
    required String label,
    required double budget,
    required double actual,
    required Color color,
  }) {
    final percentage = budget > 0 ? actual / budget : 0.0;
    final isOverspent = percentage > 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyLarge),
            Text(
              '${widget.currency} ${_currencyFormat.format(actual)} / ${widget.currency} ${_currencyFormat.format(budget)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isOverspent ? AppColors.danger : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverspent ? AppColors.danger : color,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}% of budget used',
          style: AppTextStyles.bodySmall.copyWith(
            color: isOverspent ? AppColors.danger : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _balanceBudget(String changed) {
    // Ensure total equals 100%
    final total = _needsPercentage + _wantsPercentage + _savingsPercentage;
    final diff = total - 1.0;

    if (diff.abs() > 0.01) {
      switch (changed) {
        case 'needs':
          _savingsPercentage = (1.0 - _needsPercentage - _wantsPercentage).clamp(0.05, 0.70);
          break;
        case 'wants':
          _savingsPercentage = (1.0 - _needsPercentage - _wantsPercentage).clamp(0.05, 0.70);
          break;
        case 'savings':
          _wantsPercentage = (1.0 - _needsPercentage - _savingsPercentage).clamp(0.05, 0.70);
          break;
      }
    }
  }

  void _resetToDefault() {
    setState(() {
      _needsPercentage = 0.40;
      _wantsPercentage = 0.20;
      _savingsPercentage = 0.40;
    });
  }

  void _saveBudget() async {
    final settings = _databaseService.getUserSettings();
    settings.budgetAllocations = {
      'needs': _needsPercentage,
      'wants': _wantsPercentage,
      'savings': _savingsPercentage,
    };
    await _databaseService.updateSettings(settings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.housing:
        return Icons.home;
      case TransactionCategory.groceries:
        return Icons.shopping_cart;
      case TransactionCategory.utilities:
        return Icons.electrical_services;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.medical:
        return Icons.local_hospital;
      case TransactionCategory.insurance:
        return Icons.security;
      case TransactionCategory.dining:
        return Icons.restaurant;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.subscriptions:
        return Icons.subscriptions;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.income:
        return Icons.attach_money;
      case TransactionCategory.investments:
        return Icons.trending_up;
      case TransactionCategory.uncategorized:
        return Icons.help_outline;
    }
  }
}
