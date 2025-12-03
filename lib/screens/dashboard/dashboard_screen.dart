import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/alert_card.dart';
import '../../services/database_service.dart';
import '../../services/invoice_scanner_service.dart';
import '../../models/transaction.dart';
import '../../utils/page_transitions.dart';
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
  final InvoiceScannerService _invoiceScanner = InvoiceScannerService();
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

  Future<void> _scanReceipt() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _invoiceScanner.scanInvoice();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (result == null) {
        // User cancelled
        return;
      }

      // Create transaction from scanned data
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: result.merchantName,
        merchant: result.merchantName,
        amount: -result.amount,
        date: result.date,
        category: TransactionCategory.uncategorized,
        rawText: result.rawText,
        isIncome: false,
        confirmed: false,
      );

      // Add to database
      await _databaseService.addTransaction(transaction);
      
      // Reload data
      _loadData();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Receipt scanned: AED ${_currencyFormat.format(result.amount)}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning receipt: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              elevation: 0,
              backgroundColor: AppColors.surface.withOpacity(0.8),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'Logo/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(
                'Wealth Builder',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
                const SizedBox(width: AppConstants.spacingXS),
              ],
            ),
          ),
        ),
      ),
      body: _selectedIndex == 0
          ? _buildDashboard()
          : _selectedIndex == 1
              ? _buildReports()
              : _buildSettings(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _scanReceipt,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Receipt'),
              backgroundColor: AppColors.primary,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.caption,
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
        padding: const EdgeInsets.only(
          top: 72, // Account for transparent app bar
          left: AppConstants.spacingM,
          right: AppConstants.spacingM,
          bottom: AppConstants.spacingM,
        ),
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
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          widget.userName,
          style: AppTextStyles.largeTitle,
        ),
      ],
    );
  }

  Widget _buildNetWorthCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'Net Worth',
                style: AppTextStyles.callout.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            '${widget.currency} ${_currencyFormat.format(_netWorth)}',
            style: AppTextStyles.numberLarge.copyWith(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+3.2%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                'this month',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
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
                context.pushApple(
                  InsightsScreen(
                    monthlySalary: widget.monthlySalary,
                    emergencyFundGoal: widget.emergencyFundGoal,
                    currency: widget.currency,
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.primary),
              ),
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
            context.pushApple(
              BudgetScreen(
                monthlySalary: widget.monthlySalary,
                currency: widget.currency,
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
            // TODO: Navigate to investments
          },
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        AlertCard(
          icon: Icons.receipt_long_outlined,
          title: 'Review subscription',
          description: 'Netflix inactive for 30 days. Save AED 50/month?',
          color: AppColors.primary,
          onTap: () {
            context.pushApple(
              InsightsScreen(
                monthlySalary: widget.monthlySalary,
                emergencyFundGoal: widget.emergencyFundGoal,
                currency: widget.currency,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = _databaseService.getRecentTransactions(3);
    final hasTransactions = recentTransactions.isNotEmpty;

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
                context.pushApple(const TransactionListScreen());
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                if (!hasTransactions)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.spacingM),
                    child: Text('No recent transactions'),
                  )
                else
                  ...List.generate(recentTransactions.length, (index) {
                    final t = recentTransactions[index];
                    return Column(
                      children: [
                        _buildTransactionItem(
                          t.merchant.isNotEmpty ? t.merchant : 'Unknown',
                          t.category.displayName,
                          t.amount,
                          t.date,
                          _getCategoryIcon(t.category),
                        ),
                        if (index != recentTransactions.length - 1)
                          const Divider(),
                      ],
                    );
                  }),
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
