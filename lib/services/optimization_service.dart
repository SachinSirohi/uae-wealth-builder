import '../models/transaction.dart';
import '../models/user_settings.dart';
import 'database_service.dart';

/// Optimization insight types
enum InsightType {
  categoryOverspend,
  unusedSubscription,
  investmentReady,
  anomalyDetected,
  wealthProjection,
  savingsGoal,
  budgetAlert,
}

/// Insight severity levels
enum InsightSeverity {
  info,
  warning,
  critical,
  success,
}

/// Optimization insight model
class OptimizationInsight {
  final String id;
  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String description;
  final String? actionText;
  final double? potentialSavings;
  final DateTime createdAt;
  final bool isDismissed;

  OptimizationInsight({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.actionText,
    this.potentialSavings,
    DateTime? createdAt,
    this.isDismissed = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// UAE Investment Benchmarks (static data)
class UAEBenchmarks {
  // Savings account rates
  static const double fabSaverRate = 4.75;
  static const double mashreqRate = 4.5;
  static const double sukukRate = 6.5;

  // Average UAE costs (monthly in AED)
  static const double avgDubai1BR = 7500; // 90k/yr ÷ 12
  static const double avgGroceries = 1500; // 18k/yr ÷ 12
  static const double avgUtilities = 500;
  static const double avgTransport = 800;
  static const double avgDining = 600;

  // Budget targets (40/20/40)
  static const double needsTarget = 0.40;
  static const double wantsTarget = 0.20;
  static const double savingsTarget = 0.40;
}

class OptimizationService {
  final DatabaseService _databaseService;

  OptimizationService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  /// Run all optimization checks and return insights
  List<OptimizationInsight> analyzeFinances({
    required double monthlySalary,
    required double emergencyFundGoal,
    required String currency,
  }) {
    final insights = <OptimizationInsight>[];
    final transactions = _databaseService.getTransactions();
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    // Filter current month transactions
    final currentMonthTransactions = transactions
        .where((t) => t.date.isAfter(currentMonth))
        .toList();

    // Calculate spending by category
    final spendingByCategory = _calculateSpendingByCategory(currentMonthTransactions);
    final budgetTotals = _calculateBudgetTotals(currentMonthTransactions, monthlySalary);

    // Run optimization checks
    insights.addAll(_checkCategoryOverspend(
      spendingByCategory, monthlySalary, currency));
    insights.addAll(_checkBudgetAllocation(
      budgetTotals, monthlySalary, currency));
    insights.addAll(_checkUnusedSubscriptions(transactions, currency));
    insights.addAll(_checkInvestmentOpportunities(
      budgetTotals, monthlySalary, currency));
    insights.addAll(_checkAnomalies(
      transactions, currentMonthTransactions, currency));
    insights.addAll(_checkEmergencyFund(
      budgetTotals, emergencyFundGoal, currency));
    insights.add(_calculateWealthProjection(
      monthlySalary, budgetTotals['savingsRate'] ?? 0, currency));

    return insights;
  }

  Map<TransactionCategory, double> _calculateSpendingByCategory(
      List<Transaction> transactions) {
    final Map<TransactionCategory, double> spending = {};

    for (var t in transactions) {
      if (t.isExpense) {
        spending[t.category] = (spending[t.category] ?? 0) + t.absoluteAmount;
      }
    }

    return spending;
  }

  Map<String, double> _calculateBudgetTotals(
      List<Transaction> transactions, double monthlySalary) {
    double totalIncome = 0;
    double totalNeeds = 0;
    double totalWants = 0;
    double totalSavings = 0;

    for (var t in transactions) {
      if (t.isIncome == true) {
        totalIncome += t.amount;
      } else if (t.isExpense) {
        switch (t.category.budgetType) {
          case BudgetType.needs:
            totalNeeds += t.absoluteAmount;
            break;
          case BudgetType.wants:
            totalWants += t.absoluteAmount;
            break;
          case BudgetType.savings:
            totalSavings += t.absoluteAmount;
            break;
        }
      }
    }

    final totalExpenses = totalNeeds + totalWants + totalSavings;
    final actualSavings = totalIncome > 0 ? totalIncome - totalExpenses : 0;
    final savingsRate = totalIncome > 0 ? actualSavings / totalIncome : 0;

    return {
      'income': totalIncome,
      'needs': totalNeeds,
      'wants': totalWants,
      'savings': totalSavings,
      'actualSavings': actualSavings.toDouble(),
      'savingsRate': savingsRate.toDouble(),
      'needsPercent': totalIncome > 0 ? totalNeeds / totalIncome : 0,
      'wantsPercent': totalIncome > 0 ? totalWants / totalIncome : 0,
    };
  }

  /// Check for category overspend vs UAE averages
  List<OptimizationInsight> _checkCategoryOverspend(
    Map<TransactionCategory, double> spending,
    double monthlySalary,
    String currency,
  ) {
    final insights = <OptimizationInsight>[];

    // Check Groceries
    final grocerySpend = spending[TransactionCategory.groceries] ?? 0;
    if (grocerySpend > UAEBenchmarks.avgGroceries * 1.2) {
      final excess = grocerySpend - UAEBenchmarks.avgGroceries;
      insights.add(OptimizationInsight(
        id: 'grocery_overspend_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.categoryOverspend,
        severity: InsightSeverity.warning,
        title: 'Groceries Over Budget',
        description: 'You spent $currency ${grocerySpend.toStringAsFixed(0)} on groceries, '
            'which is ${(excess / UAEBenchmarks.avgGroceries * 100).toStringAsFixed(0)}% above UAE average. '
            'Consider shopping at Lulu or Union Coop for better prices.',
        actionText: 'View grocery alternatives',
        potentialSavings: excess * 12,
      ));
    }

    // Check Dining
    final diningSpend = spending[TransactionCategory.dining] ?? 0;
    if (diningSpend > UAEBenchmarks.avgDining * 1.3) {
      final excess = diningSpend - UAEBenchmarks.avgDining;
      insights.add(OptimizationInsight(
        id: 'dining_overspend_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.categoryOverspend,
        severity: InsightSeverity.warning,
        title: 'Dining Expenses High',
        description: 'Food delivery spending of $currency ${diningSpend.toStringAsFixed(0)} is '
            '${(excess / UAEBenchmarks.avgDining * 100).toStringAsFixed(0)}% above average. '
            'Cooking at home 2 more days/week could save you $currency ${(excess * 0.5).toStringAsFixed(0)}/month.',
        actionText: 'See meal prep tips',
        potentialSavings: excess * 6,
      ));
    }

    // Check Transport
    final transportSpend = spending[TransactionCategory.transport] ?? 0;
    if (transportSpend > UAEBenchmarks.avgTransport * 1.3) {
      final excess = transportSpend - UAEBenchmarks.avgTransport;
      insights.add(OptimizationInsight(
        id: 'transport_overspend_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.categoryOverspend,
        severity: InsightSeverity.info,
        title: 'Transport Costs High',
        description: 'Spending $currency ${transportSpend.toStringAsFixed(0)} on transport. '
            'Consider carpooling or using Dubai Metro for regular commutes.',
        actionText: 'View alternatives',
        potentialSavings: excess * 12,
      ));
    }

    return insights;
  }

  /// Check budget allocation (40/20/40)
  List<OptimizationInsight> _checkBudgetAllocation(
    Map<String, double> totals,
    double monthlySalary,
    String currency,
  ) {
    final insights = <OptimizationInsight>[];

    final needsPercent = totals['needsPercent'] ?? 0;
    final wantsPercent = totals['wantsPercent'] ?? 0;
    final savingsRate = totals['savingsRate'] ?? 0;

    // Check if needs exceed 40%
    if (needsPercent > UAEBenchmarks.needsTarget + 0.05) {
      insights.add(OptimizationInsight(
        id: 'needs_high_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.budgetAlert,
        severity: InsightSeverity.warning,
        title: 'Needs Spending High',
        description: 'Essential spending is ${(needsPercent * 100).toStringAsFixed(0)}% of income '
            '(target: 40%). Review housing and utility costs for potential savings.',
        actionText: 'Review needs breakdown',
      ));
    }

    // Check if wants exceed 20%
    if (wantsPercent > UAEBenchmarks.wantsTarget + 0.05) {
      final excessWants = (wantsPercent - UAEBenchmarks.wantsTarget) * monthlySalary;
      insights.add(OptimizationInsight(
        id: 'wants_high_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.budgetAlert,
        severity: InsightSeverity.warning,
        title: 'Discretionary Spending Over Budget',
        description: 'Wants at ${(wantsPercent * 100).toStringAsFixed(0)}% (target: 20%). '
            'Reducing to 20% would free up $currency ${excessWants.toStringAsFixed(0)}/month for savings.',
        actionText: 'See spending breakdown',
        potentialSavings: excessWants * 12,
      ));
    }

    // Check savings rate
    if (savingsRate < UAEBenchmarks.savingsTarget) {
      if (savingsRate < 0.2) {
        insights.add(OptimizationInsight(
          id: 'savings_critical_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.savingsGoal,
          severity: InsightSeverity.critical,
          title: 'Savings Rate Critical',
          description: 'Current savings rate is only ${(savingsRate * 100).toStringAsFixed(0)}%. '
              'UAE cost of living requires at least 40% savings for long-term wealth building.',
          actionText: 'Create savings plan',
        ));
      } else {
        insights.add(OptimizationInsight(
          id: 'savings_low_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.savingsGoal,
          severity: InsightSeverity.warning,
          title: 'Savings Below Target',
          description: 'Savings rate at ${(savingsRate * 100).toStringAsFixed(0)}% (target: 40%). '
              'You need ${((UAEBenchmarks.savingsTarget - savingsRate) * monthlySalary).toStringAsFixed(0)} more in monthly savings.',
          actionText: 'Boost savings',
        ));
      }
    } else {
      insights.add(OptimizationInsight(
        id: 'savings_good_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.savingsGoal,
        severity: InsightSeverity.success,
        title: 'Great Savings Rate!',
        description: 'You\'re saving ${(savingsRate * 100).toStringAsFixed(0)}% of your income. '
            'Keep it up to reach your financial goals faster!',
      ));
    }

    return insights;
  }

  /// Check for unused subscriptions
  List<OptimizationInsight> _checkUnusedSubscriptions(
    List<Transaction> allTransactions,
    String currency,
  ) {
    final insights = <OptimizationInsight>[];
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

    // Find subscription transactions
    final subscriptions = allTransactions
        .where((t) => t.category == TransactionCategory.subscriptions)
        .where((t) => t.date.isAfter(threeMonthsAgo))
        .toList();

    // Group by merchant and analyze frequency
    final Map<String, List<Transaction>> byMerchant = {};
    for (var t in subscriptions) {
      final key = t.merchant.isNotEmpty ? t.merchant : t.description;
      byMerchant[key] = (byMerchant[key] ?? [])..add(t);
    }

    // Check for recurring subscriptions
    for (var entry in byMerchant.entries) {
      final transactions = entry.value;
      if (transactions.length >= 2) {
        final avgAmount = transactions.fold(0.0, (sum, t) => sum + t.absoluteAmount) / transactions.length;
        
        // Check if it looks like a monthly subscription
        if (avgAmount > 20 && avgAmount < 500) {
          insights.add(OptimizationInsight(
            id: 'subscription_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            type: InsightType.unusedSubscription,
            severity: InsightSeverity.info,
            title: 'Subscription: ${entry.key}',
            description: 'You\'re paying ~$currency ${avgAmount.toStringAsFixed(0)}/month for ${entry.key}. '
                'Are you still using this service?',
            actionText: 'Review subscription',
            potentialSavings: avgAmount * 12,
          ));
        }
      }
    }

    return insights;
  }

  /// Check for investment opportunities
  List<OptimizationInsight> _checkInvestmentOpportunities(
    Map<String, double> totals,
    double monthlySalary,
    String currency,
  ) {
    final insights = <OptimizationInsight>[];
    final unusedWantsBudget = (UAEBenchmarks.wantsTarget * monthlySalary) - (totals['wants'] ?? 0);

    if (unusedWantsBudget > 500) {
      insights.add(OptimizationInsight(
        id: 'invest_unused_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.investmentReady,
        severity: InsightSeverity.success,
        title: 'Investment Opportunity',
        description: 'You have $currency ${unusedWantsBudget.toStringAsFixed(0)} unused from your Wants budget. '
            'Consider moving it to FAB Saver (${UAEBenchmarks.fabSaverRate}% APY) or similar.',
        actionText: 'Explore options',
        potentialSavings: unusedWantsBudget * (UAEBenchmarks.fabSaverRate / 100),
      ));
    }

    // If savings rate is good, suggest investment
    final savingsRate = totals['savingsRate'] ?? 0;
    if (savingsRate >= UAEBenchmarks.savingsTarget && (totals['actualSavings'] ?? 0) > 3000) {
      insights.add(OptimizationInsight(
        id: 'invest_surplus_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.investmentReady,
        severity: InsightSeverity.success,
        title: 'Surplus for Investment',
        description: 'Your savings are on track! Consider allocating surplus to:\n'
            '• FAB Saver: ${UAEBenchmarks.fabSaverRate}%\n'
            '• Sukuk: ${UAEBenchmarks.sukukRate}%\n'
            '• Index funds for long-term growth',
        actionText: 'Compare options',
      ));
    }

    return insights;
  }

  /// Check for spending anomalies
  List<OptimizationInsight> _checkAnomalies(
    List<Transaction> allTransactions,
    List<Transaction> currentMonthTransactions,
    String currency,
  ) {
    final insights = <OptimizationInsight>[];
    
    // Calculate average spending per category over last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    
    final historicalTransactions = allTransactions
        .where((t) => t.date.isAfter(threeMonthsAgo) && t.date.isBefore(DateTime(now.year, now.month, 1)))
        .toList();

    final Map<TransactionCategory, double> historicalAvg = {};
    final Map<TransactionCategory, int> monthCount = {};

    for (var t in historicalTransactions) {
      if (t.isExpense) {
        historicalAvg[t.category] = (historicalAvg[t.category] ?? 0) + t.absoluteAmount;
        monthCount[t.category] = (monthCount[t.category] ?? 0) + 1;
      }
    }

    // Calculate averages
    for (var category in historicalAvg.keys) {
      historicalAvg[category] = historicalAvg[category]! / 3; // 3 month average
    }

    // Compare current month to historical
    final Map<TransactionCategory, double> currentSpending = {};
    for (var t in currentMonthTransactions) {
      if (t.isExpense) {
        currentSpending[t.category] = (currentSpending[t.category] ?? 0) + t.absoluteAmount;
      }
    }

    for (var entry in currentSpending.entries) {
      final historical = historicalAvg[entry.key] ?? 0;
      if (historical > 0 && entry.value > historical * 2) {
        final increase = ((entry.value / historical) - 1) * 100;
        insights.add(OptimizationInsight(
          id: 'anomaly_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          type: InsightType.anomalyDetected,
          severity: InsightSeverity.warning,
          title: '${entry.key.displayName} Spike Detected',
          description: 'Spending in ${entry.key.displayName} is up ${increase.toStringAsFixed(0)}% vs your 3-month average. '
              'Current: $currency ${entry.value.toStringAsFixed(0)} vs Avg: $currency ${historical.toStringAsFixed(0)}',
          actionText: 'Review transactions',
        ));
      }
    }

    return insights;
  }

  /// Check emergency fund progress
  List<OptimizationInsight> _checkEmergencyFund(
    Map<String, double> totals,
    double emergencyFundGoal,
    String currency,
  ) {
    final insights = <OptimizationInsight>[];
    
    // This would normally come from actual saved amount
    // For now, estimate based on cumulative savings
    final estimatedEmergencyFund = (totals['actualSavings'] ?? 0) * 0.6; // Assume 60% goes to emergency

    if (estimatedEmergencyFund < emergencyFundGoal * 0.25) {
      insights.add(OptimizationInsight(
        id: 'emergency_critical_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.savingsGoal,
        severity: InsightSeverity.critical,
        title: 'Emergency Fund Needs Attention',
        description: 'Your emergency fund is under 25% funded. '
            'Aim for $currency ${emergencyFundGoal.toStringAsFixed(0)} (6 months expenses) as a priority.',
        actionText: 'Create savings plan',
      ));
    } else if (estimatedEmergencyFund < emergencyFundGoal) {
      final progress = (estimatedEmergencyFund / emergencyFundGoal * 100);
      final remaining = emergencyFundGoal - estimatedEmergencyFund;
      insights.add(OptimizationInsight(
        id: 'emergency_progress_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.savingsGoal,
        severity: InsightSeverity.info,
        title: 'Emergency Fund Progress',
        description: 'Your emergency fund is ${progress.toStringAsFixed(0)}% complete. '
            '$currency ${remaining.toStringAsFixed(0)} more needed to reach your goal.',
        actionText: 'View progress',
      ));
    }

    return insights;
  }

  /// Calculate wealth projection
  OptimizationInsight _calculateWealthProjection(
    double monthlySalary,
    double savingsRate,
    String currency,
  ) {
    final monthlySavings = monthlySalary * savingsRate;
    final annualSavings = monthlySavings * 12;
    
    // Calculate compound growth at 7% annual return
    const annualReturn = 0.07;
    const targetWealth = 1000000.0; // 1 million AED
    
    double currentValue = 0;
    int years = 0;
    
    while (currentValue < targetWealth && years < 50) {
      currentValue = currentValue * (1 + annualReturn) + annualSavings;
      years++;
    }

    if (years < 50) {
      return OptimizationInsight(
        id: 'wealth_projection_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.wealthProjection,
        severity: InsightSeverity.success,
        title: 'Your Path to $currency 1M',
        description: 'At ${(savingsRate * 100).toStringAsFixed(0)}% savings rate with 7% annual returns, '
            'you could reach $currency 1,000,000 in $years years. '
            'Increasing savings by 5% would shorten this by ~2 years!',
        actionText: 'See projection details',
      );
    } else {
      return OptimizationInsight(
        id: 'wealth_projection_${DateTime.now().millisecondsSinceEpoch}',
        type: InsightType.wealthProjection,
        severity: InsightSeverity.warning,
        title: 'Wealth Building Plan',
        description: 'Current savings rate may need adjustment. '
            'Consider increasing to 40% to build substantial wealth within 20 years.',
        actionText: 'Adjust savings target',
      );
    }
  }
}
