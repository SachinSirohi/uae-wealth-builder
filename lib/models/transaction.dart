import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double amount; // Positive = income, Negative = expense

  @HiveField(3)
  String description;

  @HiveField(4)
  String merchant;

  @HiveField(5)
  String rawText;

  @HiveField(6)
  TransactionCategory category;

  @HiveField(7)
  bool confirmed; // User verified

  @HiveField(8)
  bool? isIncome; // Null = uncertain

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    this.merchant = '',
    this.rawText = '',
    required this.category,
    this.confirmed = false,
    this.isIncome,
  });

  // Helper to get absolute amount
  double get absoluteAmount => amount.abs();

  // Check if transaction is expense
  bool get isExpense => amount < 0;

  @override
  String toString() {
    return 'Transaction(id: $id, date: $date, amount: $amount, merchant: $merchant, category: $category)';
  }
}

@HiveType(typeId: 1)
enum TransactionCategory {
  // NEEDS (40% CAP)
  @HiveField(0)
  housing,
  @HiveField(1)
  groceries,
  @HiveField(2)
  utilities,
  @HiveField(3)
  transport,
  @HiveField(4)
  medical,
  @HiveField(5)
  insurance,

  // WANTS (20% CAP)
  @HiveField(6)
  dining,
  @HiveField(7)
  entertainment,
  @HiveField(8)
  shopping,
  @HiveField(9)
  subscriptions,
  @HiveField(10)
  travel,

  // SAVINGS/INVEST (40% MIN)
  @HiveField(11)
  income,
  @HiveField(12)
  investments,

  // Other
  @HiveField(13)
  uncategorized,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.housing:
        return 'Housing';
      case TransactionCategory.groceries:
        return 'Groceries';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.medical:
        return 'Medical';
      case TransactionCategory.insurance:
        return 'Insurance';
      case TransactionCategory.dining:
        return 'Dining';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.subscriptions:
        return 'Subscriptions';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.income:
        return 'Income';
      case TransactionCategory.investments:
        return 'Investments';
      case TransactionCategory.uncategorized:
        return 'Uncategorized';
    }
  }

  BudgetType get budgetType {
    switch (this) {
      case TransactionCategory.housing:
      case TransactionCategory.groceries:
      case TransactionCategory.utilities:
      case TransactionCategory.transport:
      case TransactionCategory.medical:
      case TransactionCategory.insurance:
        return BudgetType.needs;
      
      case TransactionCategory.dining:
      case TransactionCategory.entertainment:
      case TransactionCategory.shopping:
      case TransactionCategory.subscriptions:
      case TransactionCategory.travel:
        return BudgetType.wants;
      
      case TransactionCategory.income:
      case TransactionCategory.investments:
        return BudgetType.savings;
      
      case TransactionCategory.uncategorized:
        return BudgetType.needs; // Default to needs
    }
  }
}

@HiveType(typeId: 2)
enum BudgetType {
  @HiveField(0)
  needs, // 40%
  @HiveField(1)
  wants, // 20%
  @HiveField(2)
  savings, // 40%
}

extension BudgetTypeExtension on BudgetType {
  String get displayName {
    switch (this) {
      case BudgetType.needs:
        return 'Needs';
      case BudgetType.wants:
        return 'Wants';
      case BudgetType.savings:
        return 'Savings';
    }
  }

  double get defaultPercentage {
    switch (this) {
      case BudgetType.needs:
        return 0.40;
      case BudgetType.wants:
        return 0.20;
      case BudgetType.savings:
        return 0.40;
    }
  }
}
