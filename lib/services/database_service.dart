import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';

class DatabaseService {
  static const String _transactionsBoxName = 'transactions';
  static const String _settingsBoxName = 'settings';

  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Box<Transaction>? _transactionsBox;
  Box<UserSettings>? _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    // Boxes are already opened in main.dart, but we ensure we have references
    if (!Hive.isBoxOpen(_transactionsBoxName)) {
      _transactionsBox = await Hive.openBox<Transaction>(_transactionsBoxName);
    } else {
      _transactionsBox = Hive.box<Transaction>(_transactionsBoxName);
    }

    if (!Hive.isBoxOpen(_settingsBoxName)) {
      _settingsBox = await Hive.openBox<UserSettings>(_settingsBoxName);
    } else {
      _settingsBox = Hive.box<UserSettings>(_settingsBoxName);
    }
  }

  // ===========================================================================
  // Transaction Operations
  // ===========================================================================

  /// Get all transactions sorted by date (newest first)
  List<Transaction> getTransactions() {
    if (_transactionsBox == null) return [];
    
    final transactions = _transactionsBox!.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  /// Get recent transactions with limit
  List<Transaction> getRecentTransactions(int limit) {
    final all = getTransactions();
    return all.take(limit).toList();
  }

  /// Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBox?.put(transaction.id, transaction);
  }

  /// Add multiple transactions (e.g. from bulk SMS scan)
  Future<void> addTransactions(List<Transaction> transactions) async {
    final Map<String, Transaction> entries = {
      for (var t in transactions) t.id: t
    };
    await _transactionsBox?.putAll(entries);
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await transaction.save();
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionsBox?.delete(id);
  }

  /// Get total net worth (sum of all income - expenses)
  double getNetWorth() {
    if (_transactionsBox == null) return 0.0;
    
    double total = 0.0;
    for (var t in _transactionsBox!.values) {
      total += t.amount;
    }
    return total;
  }

  /// Get spending by category for a specific month
  Map<TransactionCategory, double> getSpendingByCategory(DateTime month) {
    if (_transactionsBox == null) return {};

    final Map<TransactionCategory, double> spending = {};
    
    for (var t in _transactionsBox!.values) {
      // Filter for specific month and only expenses
      if (t.date.year == month.year && 
          t.date.month == month.month && 
          t.isExpense) {
        
        final category = t.category;
        final amount = t.absoluteAmount;
        
        spending[category] = (spending[category] ?? 0.0) + amount;
      }
    }
    
    return spending;
  }

  // ===========================================================================
  // User Settings Operations
  // ===========================================================================

  /// Get user settings (creates default if not exists)
  UserSettings getUserSettings() {
    if (_settingsBox == null || _settingsBox!.isEmpty) {
      final defaultSettings = UserSettings();
      _settingsBox?.put('user_settings', defaultSettings);
      return defaultSettings;
    }
    return _settingsBox!.get('user_settings')!;
  }

  /// Update user settings
  Future<void> updateSettings(UserSettings settings) async {
    await _settingsBox?.put('user_settings', settings);
  }

  /// Clear all data (for reset/restore)
  Future<void> clearAllData() async {
    await _transactionsBox?.clear();
    await _settingsBox?.clear();
  }
}
