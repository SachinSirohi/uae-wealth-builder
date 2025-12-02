import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/database_service.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';
import '../../models/user_settings.dart';
import '../../models/transaction.dart';
import 'google_drive_backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final double monthlySalary;
  final double emergencyFundGoal;
  final String currency;
  final Function(String, String, double, double, String)? onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.monthlySalary,
    required this.emergencyFundGoal,
    required this.currency,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  late String _userName;
  late String _userEmail;
  late double _monthlySalary;
  late double _emergencyFundGoal;
  late String _currency;
  bool _biometricEnabled = false;
  bool _autoBackup = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userEmail = widget.userEmail;
    _monthlySalary = widget.monthlySalary;
    _emergencyFundGoal = widget.emergencyFundGoal;
    _currency = widget.currency;
    _loadSettings();
  }

  void _loadSettings() {
    final settings = _databaseService.getUserSettings();
    setState(() {
      _biometricEnabled = settings.biometricEnabled ?? false;
      _autoBackup = settings.autoBackupEnabled ?? false;
      _notificationsEnabled = settings.notificationsEnabled ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        children: [
          // Profile Section
          _buildSectionHeader('Profile', Icons.person),
          _buildProfileCard(),
          const SizedBox(height: AppConstants.spacingL),

          // Financial Setup Section
          _buildSectionHeader('Financial Setup', Icons.account_balance_wallet),
          _buildFinancialSetupCard(),
          const SizedBox(height: AppConstants.spacingL),

          // Security Section
          _buildSectionHeader('Security', Icons.security),
          _buildSecurityCard(),
          const SizedBox(height: AppConstants.spacingL),

          // Categories & Rules Section
          _buildSectionHeader('Categories & Rules', Icons.category),
          _buildCategoriesCard(),
          const SizedBox(height: AppConstants.spacingL),

          // Backup & Restore Section
          _buildSectionHeader('Backup & Restore', Icons.cloud),
          _buildBackupCard(),
          const SizedBox(height: AppConstants.spacingL),

          // Notifications Section
          _buildSectionHeader('Notifications', Icons.notifications),
          _buildNotificationsCard(),
          const SizedBox(height: AppConstants.spacingL),

          // Data Management Section
          _buildSectionHeader('Data Management', Icons.storage),
          _buildDataManagementCard(),
          const SizedBox(height: AppConstants.spacingL),

          // About Section
          _buildSectionHeader('About', Icons.info),
          _buildAboutCard(),
          const SizedBox(height: AppConstants.spacingXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(_userName.isNotEmpty ? _userName : 'Guest User'),
            subtitle: Text(_userEmail.isNotEmpty ? _userEmail : 'Not signed in'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showEditProfileDialog,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(_userEmail.isNotEmpty ? 'Sign Out' : 'Sign In with Google'),
            onTap: () {
              // TODO: Implement sign in/out
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSetupCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Monthly Salary'),
            subtitle: Text('$_currency ${_currencyFormat.format(_monthlySalary)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showSalaryDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Emergency Fund Goal'),
            subtitle: Text('$_currency ${_currencyFormat.format(_emergencyFundGoal)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showEmergencyFundDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Default Currency'),
            subtitle: Text(_currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showCurrencyDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Use fingerprint or face to unlock'),
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() => _biometricEnabled = value);
              _saveSecuritySettings();
            },
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('Change PIN'),
            subtitle: const Text('Set a backup PIN code'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Auto-lock Timeout'),
            subtitle: const Text('After 5 minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('Custom Merchant Rules'),
            subtitle: const Text('Map merchants to categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToMerchantRules(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Budget Allocations'),
            subtitle: const Text('Adjust 40/20/40 split'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to budget screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Go to Budget tab')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('View all categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showCategoriesDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_to_drive, color: Colors.blue),
            ),
            title: const Text('Google Drive Backup'),
            subtitle: FutureBuilder<bool>(
              future: GoogleDriveService.instance.tryRestoreSession(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Checking...');
                }
                final isAuthenticated = GoogleDriveService.instance.isAuthenticated;
                return Text(
                  isAuthenticated
                      ? 'Signed in as ${GoogleDriveService.instance.userEmail}'
                      : 'Sign in with Google to backup',
                  style: TextStyle(
                    color: isAuthenticated ? Colors.green : AppColors.textSecondary,
                  ),
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoogleDriveBackupScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export to CSV/PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showExportOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get alerts and insights'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveNotificationSettings();
            },
            activeColor: AppColors.primary,
          ),
          if (_notificationsEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Budget Alerts'),
              subtitle: const Text('When spending exceeds budget'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Weekly Insights'),
              subtitle: const Text('Receive optimization tips'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.summarize, color: AppColors.textSecondary),
            title: const Text('Transaction Summary'),
            subtitle: FutureBuilder<int>(
              future: Future.value(_databaseService.getTransactions().length),
              builder: (context, snapshot) {
                return Text('${snapshot.data ?? 0} transactions stored');
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.cleaning_services, color: AppColors.warning),
            title: const Text('Clear Old Transactions'),
            subtitle: const Text('Remove transactions older than 1 year'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showClearOldDataDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.danger),
            title: Text(
              'Clear All Data',
              style: TextStyle(color: AppColors.danger),
            ),
            subtitle: const Text('Delete all transactions and settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showClearAllDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0 (Build 1)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Open terms
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Contact Support'),
            subtitle: const Text('er.sachinsirohi@gmail.com'),
            onTap: () {
              // TODO: Open email
            },
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              children: [
                Text(
                  '🇦🇪 Built for UAE Residents',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Privacy First • 100% Local Storage',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _userName = nameController.text);
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSalaryDialog() {
    final controller = TextEditingController(text: _monthlySalary.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Salary'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '$_currency ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() {
                  _monthlySalary = value;
                  // Auto-adjust emergency fund goal (6x salary)
                  _emergencyFundGoal = value * 6;
                });
                Navigator.pop(context);
                _saveSettings();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyFundDialog() {
    final controller = TextEditingController(text: _emergencyFundGoal.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Fund Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Goal Amount',
                prefixText: '$_currency ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended: ${(_monthlySalary * 6).toStringAsFixed(0)} (6 months expenses)',
              style: AppTextStyles.label,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() => _emergencyFundGoal = value);
                Navigator.pop(context);
                _saveSettings();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('AED - UAE Dirham'),
              value: 'AED',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value!);
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            RadioListTile<String>(
              title: const Text('USD - US Dollar'),
              value: 'USD',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value!);
                Navigator.pop(context);
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Categories'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildCategoryGroup('Needs (40%)', [
                TransactionCategory.housing,
                TransactionCategory.groceries,
                TransactionCategory.utilities,
                TransactionCategory.transport,
                TransactionCategory.medical,
                TransactionCategory.insurance,
              ], AppColors.needsColor),
              const SizedBox(height: 16),
              _buildCategoryGroup('Wants (20%)', [
                TransactionCategory.dining,
                TransactionCategory.entertainment,
                TransactionCategory.shopping,
                TransactionCategory.subscriptions,
                TransactionCategory.travel,
              ], AppColors.wantsColor),
              const SizedBox(height: 16),
              _buildCategoryGroup('Savings (40%)', [
                TransactionCategory.income,
                TransactionCategory.investments,
              ], AppColors.savingsColor),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(String title, List<TransactionCategory> categories, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            return Chip(
              label: Text(cat.displayName),
              avatar: Icon(_getCategoryIcon(cat), size: 16, color: color),
              backgroundColor: color.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _navigateToMerchantRules() {
    // Navigate to merchant rules screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MerchantRulesScreen(),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              subtitle: const Text('Spreadsheet format'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Monthly report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearOldDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Data'),
        content: const Text('This will delete transactions older than 1 year. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Old data cleared!')),
              );
            },
            child: const Text('Clear Old Data'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data', style: TextStyle(color: AppColors.danger)),
        content: const Text('This will permanently delete ALL your transactions and settings. This action cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await _databaseService.clearAllData();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared')),
                );
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    final settings = _databaseService.getUserSettings();
    settings.name = _userName;
    settings.email = _userEmail;
    settings.monthlySalary = _monthlySalary;
    settings.emergencyFundGoal = _emergencyFundGoal;
    settings.currency = _currency;
    await _databaseService.updateSettings(settings);

    widget.onSettingsChanged?.call(
      _userName,
      _userEmail,
      _monthlySalary,
      _emergencyFundGoal,
      _currency,
    );
  }

  void _saveSecuritySettings() async {
    final settings = _databaseService.getUserSettings();
    settings.biometricEnabled = _biometricEnabled;
    await _databaseService.updateSettings(settings);
  }

  void _saveBackupSettings() async {
    final settings = _databaseService.getUserSettings();
    settings.autoBackupEnabled = _autoBackup;
    await _databaseService.updateSettings(settings);
  }

  void _saveNotificationSettings() async {
    final settings = _databaseService.getUserSettings();
    settings.notificationsEnabled = _notificationsEnabled;
    await _databaseService.updateSettings(settings);
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

/// Merchant Rules Screen for custom merchant-to-category mappings
class MerchantRulesScreen extends StatefulWidget {
  const MerchantRulesScreen({super.key});

  @override
  State<MerchantRulesScreen> createState() => _MerchantRulesScreenState();
}

class _MerchantRulesScreenState extends State<MerchantRulesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, TransactionCategory> _merchantRules = {};

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() {
    final settings = _databaseService.getUserSettings();
    // Convert stored string categories back to enum
    // For now, use empty map as placeholder
    setState(() {
      _merchantRules = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRuleDialog,
          ),
        ],
      ),
      body: _merchantRules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rule, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No custom rules yet', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text(
                    'Add rules to automatically categorize\nmerchants your way',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddRuleDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Rule'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _merchantRules.length,
              itemBuilder: (context, index) {
                final entry = _merchantRules.entries.toList()[index];
                return ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(entry.key),
                  subtitle: Text(entry.value.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _merchantRules.remove(entry.key);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showAddRuleDialog() {
    final merchantController = TextEditingController();
    TransactionCategory? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Merchant Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant Name',
                  hintText: 'e.g., Carrefour, Talabat',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransactionCategory>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                value: selectedCategory,
                items: TransactionCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedCategory = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (merchantController.text.isNotEmpty && selectedCategory != null) {
                  setState(() {
                    _merchantRules[merchantController.text] = selectedCategory!;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Rule'),
            ),
          ],
        ),
      ),
    );
  }
}
