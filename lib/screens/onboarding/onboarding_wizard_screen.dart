import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_constants.dart';
import '../../services/background_service.dart';
import '../../services/google_drive_service.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // State Variables
  String _userName = 'Guest';
  String _userEmail = '';
  bool _isGoogleLoading = false;
  String? _googleError;
  
  bool _notifAccess = false;
  bool _smsAccess = false;
  
  final TextEditingController _salaryController = TextEditingController(text: '15000');
  double _emergencyMultiplier = 6.0;
  String _selectedCurrency = 'AED';
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  @override
  void dispose() {
    _pageController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    // Save user settings and mark setup as completed
    final settingsBox = await Hive.openBox<UserSettings>('userSettings');
    final settings = UserSettings(
      name: _userName,
      email: _userEmail,
      monthlySalary: double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 15000,
      emergencyFundGoal: (double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 15000) * _emergencyMultiplier,
      currency: _selectedCurrency,
      isSetupCompleted: true, // Mark setup as completed
    );
    await settingsBox.put('settings', settings);
    
    // Initialize background service if permissions granted
    if (_smsAccess) {
      await BackgroundService.initialize();
      await BackgroundService.registerPeriodicTask();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          userName: _userName,
          userEmail: _userEmail,
          monthlySalary: double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 15000,
          emergencyFundGoal: (double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 15000) * _emergencyMultiplier,
          currency: _selectedCurrency,
        ),
      ),
    );
  }

  // --- Google Sign In Logic ---
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _googleError = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          drive.DriveApi.driveFileScope,
        ],
      );
      
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      
      if (account != null) {
        await GoogleDriveService.instance.initializeWithAccount(account);
        setState(() {
          _userName = account.displayName ?? 'User';
          _userEmail = account.email;
        });
        _nextPage();
      }
    } catch (error) {
      setState(() {
        _googleError = 'Sign in failed. Please try again.';
      });
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  // --- Permission Logic ---
  Future<void> _requestNotificationAccess() async {
    final status = await Permission.notification.request();
    setState(() {
      _notifAccess = status.isGranted;
    });
    if (_notifAccess) _nextPage();
  }

  Future<void> _requestSMSAccess() async {
    final status = await Permission.sms.request();
    setState(() {
      _smsAccess = status.isGranted;
    });
    if (_smsAccess) _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildGoogleSignInPage(),
                  _buildNotificationPermissionPage(),
                  _buildSMSPermissionPage(),
                  _buildSalaryPage(),
                  _buildEmergencyFundPage(),
                ],
              ),
            ),
            
            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _prevPage,
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    )
                  else
                    const SizedBox(width: 60), // Spacer
                    
                  if (_currentPage == 1) // Google Sign In Page special case
                    TextButton(
                      onPressed: _nextPage,
                      child: const Text('Skip', style: TextStyle(fontSize: 16)),
                    )
                  else
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1 ? 'Finish' : 'Next',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.security, size: 80, color: AppColors.primary),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Privacy First',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Your financial data is sensitive. We believe it belongs to you, and only you.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: AppColors.success),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    '100% Local Processing. No data leaves your device without your permission.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.cloud_upload, size: 80, color: AppColors.primary),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Secure Backup',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Connect Google Drive to securely backup your encrypted data. You own the backup.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          if (_googleError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: Text(
                _googleError!,
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
            icon: _isGoogleLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(_isGoogleLoading ? 'Connecting...' : 'Connect Google Drive'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildNotificationPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            _notifAccess ? Icons.notifications_active : Icons.notifications_none,
            size: 80,
            color: _notifAccess ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Auto-Tracking',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Allow notifications to instantly track transactions when you receive bank alerts.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          if (!_notifAccess)
            ElevatedButton(
              onPressed: _requestNotificationAccess,
              child: const Text('Allow Notifications'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Permission Granted', style: TextStyle(color: AppColors.success)),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSMSPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            _smsAccess ? Icons.sms : Icons.sms_outlined,
            size: 80,
            color: _smsAccess ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Smart Parsing',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'We need SMS access to read bank messages. This happens LOCALLY on your device.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'We never send your SMS data to any server. It is processed instantly and stored only in your private database.',
              style: AppTextStyles.label.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          if (!_smsAccess)
            ElevatedButton(
              onPressed: _requestSMSAccess,
              child: const Text('Allow SMS Access'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Permission Granted', style: TextStyle(color: AppColors.success)),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSalaryPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.account_balance_wallet, size: 80, color: AppColors.primary),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Monthly Income',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Enter your monthly salary to help us calculate your budget.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          TextField(
            controller: _salaryController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(fontSize: 32),
            decoration: InputDecoration(
              prefixText: '$_selectedCurrency ',
              prefixStyle: AppTextStyles.heading1.copyWith(fontSize: 32, color: AppColors.textSecondary),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
          const Divider(height: 1, thickness: 2, color: AppColors.primary),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmergencyFundPage() {
    double salary = double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 15000;
    double goal = salary * _emergencyMultiplier;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(Icons.savings, size: 80, color: AppColors.success),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Emergency Fund',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'How many months of expenses do you want to save?',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXL),
          Text(
            '${_emergencyMultiplier.toInt()} Months',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),
          Text(
            'Goal: $_selectedCurrency ${_currencyFormat.format(goal)}',
            style: AppTextStyles.heading3.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Slider(
            value: _emergencyMultiplier,
            min: 3.0,
            max: 12.0,
            divisions: 9,
            activeColor: AppColors.success,
            onChanged: (value) {
              setState(() {
                _emergencyMultiplier = value;
              });
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
