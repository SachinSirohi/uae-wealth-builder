import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';import 'package:fl_chart/fl_chart.dart';

import 'package:intl/intl.dart';import '../../constants/app_constants.dart';

import '../../constants/app_constants.dart';import '../../services/database_service.dart';

import '../../services/database_service.dart';import '../../models/transaction.dart';

import '../../models/transaction.dart';

class ReportsScreen extends StatefulWidget {

class ReportsScreen extends StatefulWidget {  const ReportsScreen({super.key});

  final double monthlySalary;

  final String currency;  @override

  State<ReportsScreen> createState() => _ReportsScreenState();

  const ReportsScreen({}

    super.key,

    required this.monthlySalary,class _ReportsScreenState extends State<ReportsScreen> {

    required this.currency,  final DatabaseService _databaseService = DatabaseService();

  });  int _touchedIndex = -1;

  String _selectedPeriod = 'This Month';

  @override

  State<ReportsScreen> createState() => _ReportsScreenState();  @override

}  Widget build(BuildContext context) {

    return Scaffold(

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {      body: CustomScrollView(

  final DatabaseService _databaseService = DatabaseService();        slivers: [

  final NumberFormat _currencyFormat = NumberFormat('#,##0');          SliverAppBar(

              title: const Text('Financial Reports'),

  int _touchedIndex = -1;            pinned: true,

  String _selectedPeriod = 'This Month';            actions: [

  late TabController _tabController;              PopupMenuButton<String>(

                initialValue: _selectedPeriod,

  // Data holders                onSelected: (value) {

  double _totalNeeds = 0;                  setState(() {

  double _totalWants = 0;                    _selectedPeriod = value;

  double _totalSavings = 0;                  });

  double _totalIncome = 0;                },

  Map<TransactionCategory, double> _categorySpending = {};                itemBuilder: (context) => [

  List<MonthlyData> _monthlyTrend = [];                  const PopupMenuItem(value: 'This Month', child: Text('This Month')),

                  const PopupMenuItem(value: 'Last Month', child: Text('Last Month')),

  @override                  const PopupMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months')),

  void initState() {                ],

    super.initState();                child: Padding(

    _tabController = TabController(length: 3, vsync: this);                  padding: const EdgeInsets.symmetric(horizontal: 16.0),

    _loadData();                  child: Row(

  }                    children: [

                      Text(_selectedPeriod, style: AppTextStyles.bodyMedium),

  @override                      const Icon(Icons.arrow_drop_down),

  void dispose() {                    ],

    _tabController.dispose();                  ),

    super.dispose();                ),

  }              ),

            ],

  void _loadData() {          ),

    final transactions = _databaseService.getTransactions();          SliverPadding(

    final now = DateTime.now();            padding: const EdgeInsets.all(AppConstants.spacingM),

            sliver: SliverList(

    // Reset values              delegate: SliverChildListDelegate([

    _totalNeeds = 0;                _buildSpendingBreakdownCard(),

    _totalWants = 0;                const SizedBox(height: AppConstants.spacingL),

    _totalSavings = 0;                _buildCategoryBreakdownCard(),

    _totalIncome = 0;              ]),

    _categorySpending = {};            ),

    _monthlyTrend = [];          ),

        ],

    // Calculate monthly data for the last 6 months      ),

    Map<String, MonthlyData> monthlyMap = {};    );

      }

    for (int i = 5; i >= 0; i--) {

      final month = DateTime(now.year, now.month - i, 1);  Widget _buildSpendingBreakdownCard() {

      final key = DateFormat('MMM').format(month);    // Calculate actual spending

      monthlyMap[key] = MonthlyData(    final transactions = _databaseService.getTransactions();

        month: key,    double needs = 0;

        income: 0,    double wants = 0;

        expense: 0,    double savings = 0;

        savings: 0,

      );    for (var t in transactions) {

    }      if (t.isExpense) {

        if (t.category.budgetType == BudgetType.needs) needs += t.absoluteAmount;

    for (var t in transactions) {        if (t.category.budgetType == BudgetType.wants) wants += t.absoluteAmount;

      final monthKey = DateFormat('MMM').format(t.date);        if (t.category.budgetType == BudgetType.savings) savings += t.absoluteAmount;

            }

      // Filter based on selected period    }

      bool include = false;

      if (_selectedPeriod == 'This Month') {    // Mock data if empty for visualization

        include = t.date.year == now.year && t.date.month == now.month;    if (needs == 0 && wants == 0 && savings == 0) {

      } else if (_selectedPeriod == 'Last Month') {      needs = 4000;

        final lastMonth = DateTime(now.year, now.month - 1, 1);      wants = 2000;

        include = t.date.year == lastMonth.year && t.date.month == lastMonth.month;      savings = 4000;

      } else {    }

        // Last 3 months

        final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);    final total = needs + wants + savings;

        include = t.date.isAfter(threeMonthsAgo);

      }    return Card(

      child: Padding(

      if (include) {        padding: const EdgeInsets.all(AppConstants.spacingL),

        if (t.isIncome == true) {        child: Column(

          _totalIncome += t.amount;          crossAxisAlignment: CrossAxisAlignment.start,

        } else if (t.isExpense) {          children: [

          final amount = t.absoluteAmount;            Text('Budget Breakdown', style: AppTextStyles.heading2),

                      const SizedBox(height: AppConstants.spacingL),

          switch (t.category.budgetType) {            AspectRatio(

            case BudgetType.needs:              aspectRatio: 1.3,

              _totalNeeds += amount;              child: PieChart(

              break;                PieChartData(

            case BudgetType.wants:                  pieTouchData: PieTouchData(

              _totalWants += amount;                    touchCallback: (FlTouchEvent event, pieTouchResponse) {

              break;                      setState(() {

            case BudgetType.savings:                        if (!event.isInterestedForInteractions ||

              _totalSavings += amount;                            pieTouchResponse == null ||

              break;                            pieTouchResponse.touchedSection == null) {

          }                          _touchedIndex = -1;

                          return;

          _categorySpending[t.category] =                         }

              (_categorySpending[t.category] ?? 0) + amount;                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;

        }                      });

      }                    },

                  ),

      // Monthly trend data                  borderData: FlBorderData(show: false),

      if (monthlyMap.containsKey(monthKey)) {                  sectionsSpace: 2,

        if (t.isIncome == true) {                  centerSpaceRadius: 40,

          monthlyMap[monthKey]!.income += t.amount;                  sections: [

        } else if (t.isExpense) {                    _buildPieSection(0, needs, total, AppColors.primary, 'Needs'),

          monthlyMap[monthKey]!.expense += t.absoluteAmount;                    _buildPieSection(1, wants, total, AppColors.secondary, 'Wants'),

        }                    _buildPieSection(2, savings, total, AppColors.success, 'Savings'),

      }                  ],

    }                ),

              ),

    // Calculate savings for each month            ),

    for (var data in monthlyMap.values) {            const SizedBox(height: AppConstants.spacingM),

      data.savings = data.income - data.expense;            _buildLegend(),

    }          ],

        ),

    _monthlyTrend = monthlyMap.values.toList();      ),

    );

    // Use mock data if empty  }

    if (_totalNeeds == 0 && _totalWants == 0 && _totalSavings == 0) {

      _totalNeeds = 4000;  PieChartSectionData _buildPieSection(

      _totalWants = 2000;    int index,

      _totalSavings = 4000;    double value,

      _totalIncome = 15000;    double total,

          Color color,

      _categorySpending = {    String title,

        TransactionCategory.housing: 2500,  ) {

        TransactionCategory.groceries: 800,    final isTouched = index == _touchedIndex;

        TransactionCategory.utilities: 400,    final fontSize = isTouched ? 18.0 : 14.0;

        TransactionCategory.transport: 300,    final radius = isTouched ? 60.0 : 50.0;

        TransactionCategory.dining: 600,    final percentage = (value / total * 100).toStringAsFixed(0);

        TransactionCategory.entertainment: 400,

        TransactionCategory.shopping: 800,    return PieChartSectionData(

        TransactionCategory.subscriptions: 200,      color: color,

      };      value: value,

      title: '$percentage%',

      _monthlyTrend = [      radius: radius,

        MonthlyData(month: 'Jul', income: 15000, expense: 9000, savings: 6000),      titleStyle: TextStyle(

        MonthlyData(month: 'Aug', income: 15000, expense: 8500, savings: 6500),        fontSize: fontSize,

        MonthlyData(month: 'Sep', income: 15500, expense: 9200, savings: 6300),        fontWeight: FontWeight.bold,

        MonthlyData(month: 'Oct', income: 15000, expense: 8800, savings: 6200),        color: Colors.white,

        MonthlyData(month: 'Nov', income: 16000, expense: 9500, savings: 6500),      ),

        MonthlyData(month: 'Dec', income: 15000, expense: 10000, savings: 5000),    );

      ];  }

    }

  Widget _buildLegend() {

    setState(() {});    return Row(

  }      mainAxisAlignment: MainAxisAlignment.spaceEvenly,

      children: [

  @override        _buildLegendItem(AppColors.primary, 'Needs'),

  Widget build(BuildContext context) {        _buildLegendItem(AppColors.secondary, 'Wants'),

    return Scaffold(        _buildLegendItem(AppColors.success, 'Savings'),

      appBar: AppBar(      ],

        title: const Text('Financial Reports'),    );

        bottom: TabBar(  }

          controller: _tabController,

          indicatorColor: AppColors.secondary,  Widget _buildLegendItem(Color color, String text) {

          tabs: const [    return Row(

            Tab(text: 'Overview'),      children: [

            Tab(text: 'Trends'),        Container(

            Tab(text: 'Categories'),          width: 12,

          ],          height: 12,

        ),          decoration: BoxDecoration(

        actions: [            color: color,

          PopupMenuButton<String>(            shape: BoxShape.circle,

            initialValue: _selectedPeriod,          ),

            onSelected: (value) {        ),

              setState(() {        const SizedBox(width: 4),

                _selectedPeriod = value;        Text(text, style: AppTextStyles.bodyMedium),

                _loadData();      ],

              });    );

            },  }

            itemBuilder: (context) => [

              const PopupMenuItem(value: 'This Month', child: Text('This Month')),  Widget _buildCategoryBreakdownCard() {

              const PopupMenuItem(value: 'Last Month', child: Text('Last Month')),    // This would be a bar chart in the future

              const PopupMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months')),    return Card(

            ],      child: Padding(

            child: Padding(        padding: const EdgeInsets.all(AppConstants.spacingL),

              padding: const EdgeInsets.symmetric(horizontal: 16.0),        child: Column(

              child: Row(          crossAxisAlignment: CrossAxisAlignment.start,

                children: [          children: [

                  Text(_selectedPeriod, style: const TextStyle(color: Colors.white)),            Text('Top Categories', style: AppTextStyles.heading2),

                  const Icon(Icons.arrow_drop_down, color: Colors.white),            const SizedBox(height: AppConstants.spacingM),

                ],            const Center(

              ),              child: Text('Category analysis coming soon'),

            ),            ),

          ),          ],

        ],        ),

      ),      ),

      body: TabBarView(    );

        controller: _tabController,  }

        children: [}

          _buildOverviewTab(),
          _buildTrendsTab(),
          _buildCategoriesTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final total = _totalNeeds + _totalWants + _totalSavings;
    final savingsRate = _totalIncome > 0 
        ? ((_totalIncome - total) / _totalIncome * 100) 
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  '${widget.currency} ${_currencyFormat.format(_totalIncome)}',
                  Icons.arrow_downward,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  '${widget.currency} ${_currencyFormat.format(total)}',
                  Icons.arrow_upward,
                  AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Net Savings',
                  '${widget.currency} ${_currencyFormat.format(_totalIncome - total)}',
                  Icons.savings,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildSummaryCard(
                  'Savings Rate',
                  '${savingsRate.toStringAsFixed(1)}%',
                  Icons.percent,
                  savingsRate >= 40 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Pie Chart
          _buildSpendingPieChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.spacingXS),
                Text(title, style: AppTextStyles.label),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingPieChart() {
    final total = _totalNeeds + _totalWants + _totalSavings;
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              Icon(Icons.pie_chart, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: AppConstants.spacingM),
              Text('No spending data available', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending Breakdown', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacingL),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    _buildPieSection(0, _totalNeeds, total, AppColors.needsColor, 'Needs'),
                    _buildPieSection(1, _totalWants, total, AppColors.wantsColor, 'Wants'),
                    _buildPieSection(2, _totalSavings, total, AppColors.savingsColor, 'Savings'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildPieLegend(total),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(
    int index,
    double value,
    double total,
    Color color,
    String title,
  ) {
    final isTouched = index == _touchedIndex;
    final fontSize = isTouched ? 16.0 : 12.0;
    final radius = isTouched ? 70.0 : 60.0;
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';

    return PieChartSectionData(
      color: color,
      value: value,
      title: '$percentage%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      badgeWidget: isTouched ? _buildBadge(title, value) : null,
      badgePositionPercentageOffset: 1.3,
    );
  }

  Widget _buildBadge(String title, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$title\n${widget.currency} ${_currencyFormat.format(value)}',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPieLegend(double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(AppColors.needsColor, 'Needs', _totalNeeds, total),
        _buildLegendItem(AppColors.wantsColor, 'Wants', _totalWants, total),
        _buildLegendItem(AppColors.savingsColor, 'Savings', _totalSavings, total),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, double value, double total) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(text, style: AppTextStyles.bodyMedium),
          ],
        ),
        Text(
          '${widget.currency} ${_currencyFormat.format(value)}',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        Text('$percentage%', style: AppTextStyles.label),
      ],
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIncomeVsExpenseChart(),
          const SizedBox(height: AppConstants.spacingL),
          _buildSavingsRateTrendChart(),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseChart() {
    if (_monthlyTrend.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: AppConstants.spacingM),
              Text('No trend data available', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    double maxY = 0;
    for (var data in _monthlyTrend) {
      if (data.income > maxY) maxY = data.income;
      if (data.expense > maxY) maxY = data.expense;
    }
    maxY = (maxY * 1.2).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income vs Expenses', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacingS),
            Text('Last 6 months', style: AppTextStyles.label),
            const SizedBox(height: AppConstants.spacingL),
            AspectRatio(
              aspectRatio: 1.5,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: AppTextStyles.label,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _monthlyTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _monthlyTrend[index].month,
                                style: AppTextStyles.label,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (_monthlyTrend.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // Income line
                    LineChartBarData(
                      spots: _monthlyTrend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.income);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                    // Expense line
                    LineChartBarData(
                      spots: _monthlyTrend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.expense);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.danger,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.danger.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegendItem(AppColors.success, 'Income'),
                const SizedBox(width: AppConstants.spacingL),
                _buildChartLegendItem(AppColors.danger, 'Expenses'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRateTrendChart() {
    if (_monthlyTrend.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Savings', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacingL),
            AspectRatio(
              aspectRatio: 2.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _monthlyTrend.map((e) => e.savings.abs()).reduce((a, b) => a > b ? a : b) * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: AppTextStyles.label,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _monthlyTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _monthlyTrend[index].month,
                                style: AppTextStyles.label,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _monthlyTrend.asMap().entries.map((e) {
                    final isPositive = e.value.savings >= 0;
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.savings.abs(),
                          color: isPositive ? AppColors.success : AppColors.danger,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    // Sort categories by spending amount
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpending = sortedCategories.fold(0.0, (sum, e) => sum + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Spending Categories', style: AppTextStyles.heading2),
                  const SizedBox(height: AppConstants.spacingL),
                  if (sortedCategories.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Column(
                          children: [
                            Icon(Icons.category, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: AppConstants.spacingM),
                            Text('No category data available', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    )
                  else
                    ...sortedCategories.take(10).map((entry) {
                      return _buildCategoryRow(entry.key, entry.value, totalSpending);
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildCategoryBarChart(sortedCategories.take(5).toList(), totalSpending),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(TransactionCategory category, double amount, double total) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;
    final color = _getCategoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getCategoryIcon(category), color: color, size: 20),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(category.displayName, style: AppTextStyles.bodyLarge),
                ],
              ),
              Text(
                '${widget.currency} ${_currencyFormat.format(amount)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              SizedBox(
                width: 50,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(List<MapEntry<TransactionCategory, double>> categories, double total) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final maxValue = categories.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 Categories', style: AppTextStyles.heading2),
            const SizedBox(height: AppConstants.spacingL),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 4,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: AppTextStyles.label,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < categories.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                categories[index].key.displayName.substring(0, 4),
                                style: AppTextStyles.label,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: categories.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.value,
                          color: _getCategoryColor(e.value.key),
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category.budgetType) {
      case BudgetType.needs:
        return AppColors.needsColor;
      case BudgetType.wants:
        return AppColors.wantsColor;
      case BudgetType.savings:
        return AppColors.savingsColor;
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

class MonthlyData {
  final String month;
  double income;
  double expense;
  double savings;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
    required this.savings,
  });
}
