import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  String _filter = 'All'; // All, Income, Expense

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Income', child: Text('Income')),
              const PopupMenuItem(value: 'Expense', child: Text('Expense')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Transaction>('transactions').listenable(),
        builder: (context, Box<Transaction> box, _) {
          var transactions = box.values.toList();
          
          // Sort by date descending
          transactions.sort((a, b) => b.date.compareTo(a.date));

          // Apply filter
          if (_filter == 'Income') {
            transactions = transactions.where((t) => !t.isExpense).toList();
          } else if (_filter == 'Expense') {
            transactions = transactions.where((t) => t.isExpense).toList();
          }

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'No transactions found',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Group by date
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add manual transaction
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isExpense = transaction.isExpense;
    final color = isExpense ? AppColors.danger : AppColors.success;
    final icon = _getCategoryIcon(transaction.category);

    return Dismissible(
      key: Key(transaction.id),
      background: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacingL),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _databaseService.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            transaction.merchant.isNotEmpty ? transaction.merchant : 'Unknown Merchant',
            style: AppTextStyles.heading3.copyWith(fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.category.displayName,
                style: AppTextStyles.label,
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(transaction.date),
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
            ],
          ),
          trailing: Text(
            '${isExpense ? '' : '+'}${_currencyFormat.format(transaction.absoluteAmount)}',
            style: AppTextStyles.numberMedium.copyWith(
              color: color,
              fontSize: 16,
            ),
          ),
          onTap: () {
            // TODO: Edit transaction
          },
        ),
      ),
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
