import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../dashboard/dashboard_screen.dart';

class QuickSetupScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const QuickSetupScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  final TextEditingController _salaryController = TextEditingController(text: '15000');
  double _emergencyMultiplier = 6.0;
  String _selectedCurrency = 'AED';
  
  final List<String> _currencies = ['AED', 'USD'];
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  double get _monthlySalary {
    return double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 15000;
  }

  double get _emergencyFundGoal {
    return _monthlySalary * _emergencyMultiplier;
  }

  void _navigateToDashboard() {
    // TODO: Save settings to Hive
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          monthlySalary: _monthlySalary,
          emergencyFundGoal: _emergencyFundGoal,
          currency: _selectedCurrency,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Text(
                'Hi ${widget.userName}! 👋',
                style: AppTextStyles.heading1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              Text(
                'Let\'s set up your financial profile',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Monthly Salary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Text(
                            'Monthly Salary',
                            style: AppTextStyles.heading2,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      TextField(
                        controller: _salaryController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.numberLarge.copyWith(fontSize: 24),
                        decoration: InputDecoration(
                          labelText: 'Enter your monthly salary',
                          prefixText: '$_selectedCurrency ',
                          prefixStyle: AppTextStyles.numberLarge.copyWith(fontSize: 24),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Refresh to update emergency fund
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      Text(
                        'Range: $_selectedCurrency 10,000 - 50,000',
                        style: AppTextStyles.label,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              // Currency Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Text(
                            'Primary Currency',
                            style: AppTextStyles.heading2,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      Row(
                        children: _currencies.map((currency) {
                          final isSelected = currency == _selectedCurrency;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCurrency = currency;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? AppColors.secondary.withOpacity(0.1)
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.cardBorder,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  currency,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              // Emergency Fund Goal Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings,
                            color: AppColors.success,
                            size: 28,
                          ),
                          const SizedBox(width: AppConstants.spacingM),
                          Text(
                            'Emergency Fund Goal',
                            style: AppTextStyles.heading2,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Goal Amount Display
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '$_selectedCurrency ${_currencyFormat.format(_emergencyFundGoal)}',
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 32,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_emergencyMultiplier.toInt()}x monthly salary',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Slider
                      Row(
                        children: [
                          Text('3x', style: AppTextStyles.label),
                          Expanded(
                            child: Slider(
                              value: _emergencyMultiplier,
                              min: 3.0,
                              max: 12.0,
                              divisions: 9,
                              label: '${_emergencyMultiplier.toInt()}x',
                              activeColor: AppColors.success,
                              onChanged: (value) {
                                setState(() {
                                  _emergencyMultiplier = value;
                                });
                              },
                            ),
                          ),
                          Text('12x', style: AppTextStyles.label),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Text(
                                'Recommended: 6 months of expenses',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Start Tracking Button
              ElevatedButton(
                onPressed: _navigateToDashboard,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Start Tracking',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
