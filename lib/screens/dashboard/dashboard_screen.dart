import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/alert_card.dart';
import '../../services/database_service.dart';
import '../../models/transaction.dart';
import 'transaction_list_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../insights/insights_screen.dart';
import '../budget/budget_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final double monthlySalary;
  final double emergencyFundGoal;
  final String currency;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.monthlySalary,
    required this.emergencyFundGoal,
    required this.currency,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  double _netWorth = 0;
  double _savingsRate = 0;
  double _emergencyFund = 0;
  double _needsSpent = 0;
  double _wantsSpent = 0;
  double _savingsSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _netWorth = _databaseService.getNetWorth();
      
      final transactions = _databaseService.getTransactions();
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      
      double income = 0;
      double expenses = 0;
      _needsSpent = 0;
      _wantsSpent = 0;
      _savingsSpent = 0;
      _emergencyFund = 0; // In real app, this would be a specific account balance

      for (var t in transactions) {
        // Calculate Emergency Fund (simplified: sum of all savings/investments)
        if (t.category == TransactionCategory.investments || 
            t.category == TransactionCategory.income) {
           // This logic needs refinement based on actual account mapping
           // For MVP, we'll assume savings category contributes to emergency fund
        }

        // Current Month Calculations
        if (t.date.isAfter(currentMonth)) {
        if (t.isIncome == true) {
            income += t.amount;
          } else {
            expenses += t.absoluteAmount;
            
            if (t.category.budgetType == BudgetType.needs) {
              _needsSpent += t.absoluteAmount;
            } else if (t.category.budgetType == BudgetType.wants) {
              _wantsSpent += t.absoluteAmount;
            } else {
              _savingsSpent += t.absoluteAmount;
            }
          }
        }
      }

      // Savings Rate = (Income - Expenses) / Income
      if (income > 0) {
        _savingsRate = (income - expenses) / income;
      } else {
        _savingsRate = 0;
      }
      
      // For MVP demo, let's keep some mock values if DB is empty
      if (transactions.isEmpty) {
        _netWorth = 45230;
        _savingsRate = 0.38;
        _emergencyFund = 18000;
        _needsSpent = widget.monthlySalary * 0.35;
        _wantsSpent = widget.monthlySalary * 0.15;
        _savingsSpent = widget.monthlySalary * 0.38;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
              ? _buildReports()
              : _buildSettings(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh data
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting
            _buildGreeting(),
            const SizedBox(height: AppConstants.spacingL),
            
            // Net Worth Card (Main Metric)
            _buildNetWorthCard(),
            const SizedBox(height: AppConstants.spacingM),
            
            // Savings Rate Card
            BudgetProgressCard(
              title: 'Savings Rate',
              currentValue: _savingsRate * widget.monthlySalary,
              targetValue: 0.40 * widget.monthlySalary,
              percentage: _savingsRate,
              targetPercentage: 0.40,
              currency: widget.currency,
              color: _savingsRate >= 0.40 ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: AppConstants.spacingM),
            
            // Emergency Fund Card
            BudgetProgressCard(
              title: 'Emergency Fund',
              currentValue: _emergencyFund,
              targetValue: widget.emergencyFundGoal,
              percentage: _emergencyFund / widget.emergencyFundGoal,
              targetPercentage: 1.0,
              currency: widget.currency,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppConstants.spacingL),
            
            // Budget Overview
            _buildBudgetOverview(),
            const SizedBox(height: AppConstants.spacingL),
            
            // Alerts Section
            _buildAlertsSection(),
            const SizedBox(height: AppConstants.spacingL),
            
            // Recent Transactions
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.userName,
          style: AppTextStyles.heading1.copyWith(fontSize: 28),
        ),
      ],
    );
  }

  Widget _buildNetWorthCard() {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  'Net Worth',
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              '${widget.currency} ${_currencyFormat.format(_netWorth)}',
              style: AppTextStyles.heading1.copyWith(
                fontSize: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '+3.2% this month',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Breakdown',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Needs',
                value: _needsSpent,
                currency: widget.currency,
                color: AppColors.primary,
                subtitle: '${((_needsSpent / (widget.monthlySalary * 0.40)) * 100).toStringAsFixed(0)}% of budget',
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: StatCard(
                title: 'Wants',
                value: _wantsSpent,
                currency: widget.currency,
                color: AppColors.secondary,
                subtitle: '${((_wantsSpent / (widget.monthlySalary * 0.20)) * 100).toStringAsFixed(0)}% of budget',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        StatCard(
          title: 'Savings',
          value: _savingsSpent,
          currency: widget.currency,
          color: AppColors.success,
          subtitle: '${((_savingsSpent / (widget.monthlySalary * 0.40)) * 100).toStringAsFixed(0)}% of budget',
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alerts & Insights',
              style: AppTextStyles.heading2,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InsightsScreen(
                      monthlySalary: widget.monthlySalary,
                      emergencyFundGoal: widget.emergencyFundGoal,
                      currency: widget.currency,
                    ),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        AlertCard(
          icon: Icons.warning_amber_rounded,
          title: 'Groceries +15% over budget',
          description: 'Spent AED 1,725 vs budget of AED 1,500',
          color: AppColors.warning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BudgetScreen(
                  monthlySalary: widget.monthlySalary,
                  currency: widget.currency,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        AlertCard(
          icon: Icons.lightbulb_outline,
          title: 'Investment Opportunity',
          description: 'You have AED 500 unused wants. FAB Saver offers 4.75% APY',
          color: AppColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InsightsScreen(
                  monthlySalary: widget.monthlySalary,
                  emergencyFundGoal: widget.emergencyFundGoal,
                  currency: widget.currency,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        AlertCard(
          icon: Icons.receipt_long_outlined,
          title: 'Review subscription',
          description: 'Netflix inactive for 30 days. Save AED 50/month?',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InsightsScreen(
                  monthlySalary: widget.monthlySalary,
                  emergencyFundGoal: widget.emergencyFundGoal,
                  currency: widget.currency,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTextStyles.heading2,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionListScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                if (_databaseService.getTransactions().isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.spacingM),
                    child: Text('No recent transactions'),
                  )
                else
                  ..._databaseService.getRecentTransactions(3).map((t) => Column(
                    children: [
                      _buildTransactionItem(
                        t.merchant.isNotEmpty ? t.merchant : 'Unknown',
                        t.category.displayName,
                        t.amount,
                        t.date,
                        _getCategoryIcon(t.category),
                      ),
                      const Divider(),
                    ],
                  )).toList()..removeLast(), // Remove last divider
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String merchant,
    String category,
    double amount,
    DateTime date,
    IconData icon,
  ) {
    final isExpense = amount < 0;
    final color = isExpense ? AppColors.danger : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: AppTextStyles.heading3.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: AppTextStyles.label.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '' : '+'}${widget.currency} ${_currencyFormat.format(amount.abs())}',
                style: AppTextStyles.numberMedium.copyWith(
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, HH:mm').format(date),
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReports() {
    return const ReportsScreen();
  }

  Widget _buildSettings() {
    return SettingsScreen(
      userName: widget.userName,
      userEmail: widget.userEmail,
      monthlySalary: widget.monthlySalary,
      emergencyFundGoal: widget.emergencyFundGoal,
      currency: widget.currency,
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.housing: return Icons.home;
      case TransactionCategory.groceries: return Icons.shopping_cart;
      case TransactionCategory.utilities: return Icons.bolt;
      case TransactionCategory.transport: return Icons.directions_car;
      case TransactionCategory.medical: return Icons.medical_services;
      case TransactionCategory.insurance: return Icons.security;
      case TransactionCategory.dining: return Icons.restaurant;
      case TransactionCategory.entertainment: return Icons.movie;
      case TransactionCategory.shopping: return Icons.shopping_bag;
      case TransactionCategory.subscriptions: return Icons.subscriptions;
      case TransactionCategory.travel: return Icons.flight;
      case TransactionCategory.income: return Icons.attach_money;
      case TransactionCategory.investments: return Icons.trending_up;
      case TransactionCategory.uncategorized: return Icons.help_outline;
    }
  }
}
