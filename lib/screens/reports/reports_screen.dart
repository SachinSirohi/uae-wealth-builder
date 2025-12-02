import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/database_service.dart';
import '../../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');
  
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Year'];
  
  // Data variables
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _needsSpent = 0;
  double _wantsSpent = 0;
  double _savingsSpent = 0;
  List<Map<String, dynamic>> _monthlyData = [];
  Map<String, double> _categoryBreakdown = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final transactions = _databaseService.getTransactions();
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    setState(() {
      _totalIncome = 0;
      _totalExpenses = 0;
      _needsSpent = 0;
      _wantsSpent = 0;
      _savingsSpent = 0;
      _categoryBreakdown = {};
      
      // Calculate current month data
      for (var t in transactions) {
        if (t.date.isAfter(currentMonth)) {
          if (t.isIncome == true) {
            _totalIncome += t.amount;
          } else {
            _totalExpenses += t.absoluteAmount;
            
            // Category breakdown
            final categoryName = t.category.toString().split('.').last;
            _categoryBreakdown[categoryName] = 
                (_categoryBreakdown[categoryName] ?? 0) + t.absoluteAmount;
            
            // Budget type breakdown
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
      
      // Generate monthly trend data (last 6 months)
      _monthlyData = [];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i);
        double monthIncome = 0;
        double monthExpenses = 0;
        
        for (var t in transactions) {
          if (t.date.year == month.year && t.date.month == month.month) {
            if (t.isIncome == true) {
              monthIncome += t.amount;
            } else {
              monthExpenses += t.absoluteAmount;
            }
          }
        }
        
        _monthlyData.add({
          'month': DateFormat('MMM').format(month),
          'income': monthIncome,
          'expenses': monthExpenses,
        });
      }
      
      // Mock data if empty
      if (transactions.isEmpty) {
        _totalIncome = 25000;
        _totalExpenses = 15500;
        _needsSpent = 8750;
        _wantsSpent = 3750;
        _savingsSpent = 3000;
        
        _categoryBreakdown = {
          'housing': 5000,
          'food': 2500,
          'transportation': 1250,
          'shopping': 2000,
          'entertainment': 1750,
          'healthcare': 1000,
          'other': 2000,
        };
        
        _monthlyData = [
          {'month': 'Aug', 'income': 24000.0, 'expenses': 14500.0},
          {'month': 'Sep', 'income': 24500.0, 'expenses': 15200.0},
          {'month': 'Oct', 'income': 25000.0, 'expenses': 14800.0},
          {'month': 'Nov', 'income': 24200.0, 'expenses': 15600.0},
          {'month': 'Dec', 'income': 26000.0, 'expenses': 16200.0},
          {'month': 'Jan', 'income': 25000.0, 'expenses': 15500.0},
        ];
      }
    });
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
              title: Text(
                'Reports',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                // Period selector
                Container(
                  margin: const EdgeInsets.only(right: AppConstants.spacingM),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.callout,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Categories'),
                  Tab(text: 'Trends'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 112), // Account for app bar + tabs
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildCategoriesTab(),
            _buildTrendsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final netCashFlow = _totalIncome - _totalExpenses;
    final savingsRate = _totalIncome > 0 ? (_totalIncome - _totalExpenses) / _totalIncome : 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Income vs Expenses Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Income',
                  amount: _totalIncome,
                  icon: Icons.arrow_downward,
                  color: AppColors.success,
                  trend: '+5.2%',
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildMetricCard(
                  title: 'Expenses',
                  amount: _totalExpenses,
                  icon: Icons.arrow_upward,
                  color: AppColors.error,
                  trend: '-2.3%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          // Net Cash Flow Card
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  netCashFlow >= 0 ? AppColors.success : AppColors.error,
                  (netCashFlow >= 0 ? AppColors.success : AppColors.error).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: (netCashFlow >= 0 ? AppColors.success : AppColors.error).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Cash Flow',
                  style: AppTextStyles.callout.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'AED ${_currencyFormat.format(netCashFlow)}',
                  style: AppTextStyles.numberLarge.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  'Savings Rate: ${(savingsRate * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Budget Allocation Pie Chart
          Text(
            'Budget Allocation',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Container(
            height: 280,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildBudgetPieChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final sortedCategories = _categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Spending by Category',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          ...sortedCategories.map((entry) {
            final percentage = _totalExpenses > 0 
                ? (entry.value / _totalExpenses) * 100 
                : 0;
            final categoryColor = _getCategoryColor(entry.key);
            
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Text(
                            _formatCategoryName(entry.key),
                            style: AppTextStyles.callout.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'AED ${_currencyFormat.format(entry.value)}',
                            style: AppTextStyles.callout.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: categoryColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Income vs Expenses Trend',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Container(
            height: 300,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildTrendChart(),
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Monthly comparison cards
          Text(
            'Monthly Comparison',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppConstants.spacingM),
          ..._monthlyData.take(3).map((data) {
            final month = data['month'] as String;
            final income = data['income'] as double;
            final expenses = data['expenses'] as double;
            final net = income - expenses;
            
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        month,
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Net: AED ${_currencyFormat.format(net)}',
                        style: AppTextStyles.caption.copyWith(
                          color: net >= 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'In',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            _currencyFormat.format(income),
                            style: AppTextStyles.callout.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Out',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            _currencyFormat.format(expenses),
                            style: AppTextStyles.callout.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                ),
                child: Text(
                  trend,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AED ${_currencyFormat.format(amount)}',
            style: AppTextStyles.numberMedium.copyWith(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPieChart() {
    final total = _needsSpent + _wantsSpent + _savingsSpent;
    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: AppColors.needsColor,
                  value: _needsSpent,
                  title: '${((_needsSpent / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.wantsColor,
                  value: _wantsSpent,
                  title: '${((_wantsSpent / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                PieChartSectionData(
                  color: AppColors.savingsColor,
                  value: _savingsSpent,
                  title: '${((_savingsSpent / total) * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingL),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Needs', _needsSpent, AppColors.needsColor),
              const SizedBox(height: AppConstants.spacingS),
              _buildLegendItem('Wants', _wantsSpent, AppColors.wantsColor),
              const SizedBox(height: AppConstants.spacingS),
              _buildLegendItem('Savings', _savingsSpent, AppColors.savingsColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _currencyFormat.format(amount),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_monthlyData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }
    
    final maxValue = _monthlyData.fold<double>(
      0,
      (prev, data) => [
        prev,
        data['income'] as double,
        data['expenses'] as double,
      ].reduce((a, b) => a > b ? a : b),
    );
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _monthlyData.length) return const Text('');
                return Text(
                  _monthlyData[value.toInt()]['month'] as String,
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: AppTextStyles.caption,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_monthlyData.length, (index) {
          final data = _monthlyData[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data['income'] as double,
                color: AppColors.success,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: data['expenses'] as double,
                color: AppColors.error,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.needsColor,
      AppColors.wantsColor,
      AppColors.savingsColor,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[category.hashCode % colors.length];
  }

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }
}
