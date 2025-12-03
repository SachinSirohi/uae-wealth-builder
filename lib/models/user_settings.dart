import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 3)
class UserSettings extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String email;

  @HiveField(2)
  double monthlySalary;

  @HiveField(3)
  double emergencyFundGoal;

  @HiveField(4)
  Map<String, double> budgetAllocations; // Category -> Amount

  @HiveField(5)
  String currency;

  @HiveField(6)
  bool biometricEnabled;

  @HiveField(7)
  bool backupEnabled;

  @HiveField(8)
  DateTime? lastBackupDate;

  @HiveField(9)
  Map<String, String> customRules; // Merchant -> Category mapping

  @HiveField(10)
  bool? autoBackupEnabled;

  @HiveField(11)
  bool? notificationsEnabled;

  @HiveField(12)
  bool isSetupCompleted;

  UserSettings({
    this.name = '',
    this.email = '',
    this.monthlySalary = 10000.0,
    double? emergencyFundGoal,
    Map<String, double>? budgetAllocations,
    this.currency = 'AED',
    this.biometricEnabled = false,
    this.backupEnabled = false,
    this.lastBackupDate,
    Map<String, String>? customRules,
    this.autoBackupEnabled,
    this.notificationsEnabled,
    this.isSetupCompleted = false,
  })  : emergencyFundGoal = emergencyFundGoal ?? (monthlySalary * 6),
        budgetAllocations = budgetAllocations ?? _defaultBudgetAllocations(),
        customRules = customRules ?? {};

  static Map<String, double> _defaultBudgetAllocations() {
    return {
      'needs': 0.40,
      'wants': 0.20,
      'savings': 0.40,
    };
  }

  // Helper methods
  double get needsAllocation => budgetAllocations['needs'] ?? 0.40;
  double get wantsAllocation => budgetAllocations['wants'] ?? 0.20;
  double get savingsAllocation => budgetAllocations['savings'] ?? 0.40;

  double get needsAmount => monthlySalary * needsAllocation;
  double get wantsAmount => monthlySalary * wantsAllocation;
  double get savingsAmount => monthlySalary * savingsAllocation;

  void updateBudgetAllocation(String type, double percentage) {
    budgetAllocations[type] = percentage;
    save();
  }

  void updateMonthlySalary(double salary) {
    monthlySalary = salary;
    emergencyFundGoal = salary * 6; // Auto-adjust emergency fund
    save();
  }

  void addCustomRule(String merchant, String category) {
    customRules[merchant.toLowerCase()] = category;
    save();
  }

  String? getCustomCategory(String merchant) {
    return customRules[merchant.toLowerCase()];
  }
}
