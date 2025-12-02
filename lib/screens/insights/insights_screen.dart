import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/optimization_service.dart';

class InsightsScreen extends StatefulWidget {
  final double monthlySalary;
  final double emergencyFundGoal;
  final String currency;

  const InsightsScreen({
    super.key,
    required this.monthlySalary,
    required this.emergencyFundGoal,
    required this.currency,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final OptimizationService _optimizationService = OptimizationService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');
  
  List<OptimizationInsight> _insights = [];
  Set<String> _dismissedIds = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  void _loadInsights() {
    setState(() => _isLoading = true);
    
    final insights = _optimizationService.analyzeFinances(
      monthlySalary: widget.monthlySalary,
      emergencyFundGoal: widget.emergencyFundGoal,
      currency: widget.currency,
    );

    setState(() {
      _insights = insights.where((i) => !_dismissedIds.contains(i.id)).toList();
      _isLoading = false;
    });
  }

  List<OptimizationInsight> get _filteredInsights {
    if (_selectedFilter == 'All') {
      return _insights;
    }

    return _insights.where((insight) {
      switch (_selectedFilter) {
        case 'Critical':
          return insight.severity == InsightSeverity.critical;
        case 'Warnings':
          return insight.severity == InsightSeverity.warning;
        case 'Success':
          return insight.severity == InsightSeverity.success;
        case 'Savings':
          return insight.potentialSavings != null && insight.potentialSavings! > 0;
        default:
          return true;
      }
    }).toList();
  }

  double get _totalPotentialSavings {
    return _insights
        .where((i) => i.potentialSavings != null)
        .fold(0.0, (sum, i) => sum + i.potentialSavings!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadInsights(),
              child: CustomScrollView(
                slivers: [
                  // Summary Card
                  SliverToBoxAdapter(
                    child: _buildSummaryCard(),
                  ),
                  
                  // Filter Chips
                  SliverToBoxAdapter(
                    child: _buildFilterChips(),
                  ),
                  
                  // Insights List
                  _filteredInsights.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(AppConstants.spacingM),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildInsightCard(_filteredInsights[index]);
                              },
                              childCount: _filteredInsights.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final criticalCount = _insights.where((i) => i.severity == InsightSeverity.critical).length;
    final warningCount = _insights.where((i) => i.severity == InsightSeverity.warning).length;
    final successCount = _insights.where((i) => i.severity == InsightSeverity.success).length;

    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF008B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
              const Text(
                'Potential Annual Savings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_insights.length} insights',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            '${widget.currency} ${_currencyFormat.format(_totalPotentialSavings)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              _buildSummaryChip(Icons.warning_rounded, criticalCount, AppColors.danger),
              const SizedBox(width: AppConstants.spacingS),
              _buildSummaryChip(Icons.info_outline, warningCount, AppColors.warning),
              const SizedBox(width: AppConstants.spacingS),
              _buildSummaryChip(Icons.check_circle_outline, successCount, AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Critical', 'Warnings', 'Success', 'Savings'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppConstants.spacingS),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInsightCard(OptimizationInsight insight) {
    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _dismissedIds.add(insight.id);
          _insights.removeWhere((i) => i.id == insight.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insight dismissed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _dismissedIds.remove(insight.id);
                  _loadInsights();
                });
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: BorderSide(
            color: _getSeverityColor(insight.severity).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showInsightDetails(insight),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(insight.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getInsightIcon(insight.type),
                        color: _getSeverityColor(insight.severity),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildSeverityBadge(insight.severity),
                              if (insight.potentialSavings != null) ...[
                                const Spacer(),
                                Text(
                                  '+${widget.currency} ${_currencyFormat.format(insight.potentialSavings)}/yr',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingXS),
                          Text(
                            insight.title,
                            style: AppTextStyles.heading3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  insight.description,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (insight.actionText != null) ...[
                  const SizedBox(height: AppConstants.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showInsightDetails(insight),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(insight.actionText!),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(InsightSeverity severity) {
    String text;
    Color color;

    switch (severity) {
      case InsightSeverity.critical:
        text = 'Critical';
        color = AppColors.danger;
        break;
      case InsightSeverity.warning:
        text = 'Warning';
        color = AppColors.warning;
        break;
      case InsightSeverity.success:
        text = 'Good';
        color = AppColors.success;
        break;
      case InsightSeverity.info:
        text = 'Info';
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'All Clear!',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'No insights in this category.\nYour finances are looking good!',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return AppColors.danger;
      case InsightSeverity.warning:
        return AppColors.warning;
      case InsightSeverity.success:
        return AppColors.success;
      case InsightSeverity.info:
        return AppColors.primary;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.categoryOverspend:
        return Icons.trending_up;
      case InsightType.unusedSubscription:
        return Icons.subscriptions;
      case InsightType.investmentReady:
        return Icons.savings;
      case InsightType.anomalyDetected:
        return Icons.warning_amber;
      case InsightType.wealthProjection:
        return Icons.timeline;
      case InsightType.savingsGoal:
        return Icons.flag;
      case InsightType.budgetAlert:
        return Icons.pie_chart;
    }
  }

  void _showInsightDetails(OptimizationInsight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppConstants.spacingL),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(insight.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getInsightIcon(insight.type),
                        color: _getSeverityColor(insight.severity),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeverityBadge(insight.severity),
                          const SizedBox(height: AppConstants.spacingXS),
                          Text(insight.title, style: AppTextStyles.heading2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingL),
                Text(insight.description, style: AppTextStyles.bodyLarge),
                if (insight.potentialSavings != null) ...[
                  const SizedBox(height: AppConstants.spacingL),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings, color: AppColors.success),
                        const SizedBox(width: AppConstants.spacingM),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Potential Annual Savings',
                              style: AppTextStyles.label,
                            ),
                            Text(
                              '${widget.currency} ${_currencyFormat.format(insight.potentialSavings)}',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingL),
                if (insight.actionText != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to relevant action
                      },
                      child: Text(insight.actionText!),
                    ),
                  ),
                const SizedBox(height: AppConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
