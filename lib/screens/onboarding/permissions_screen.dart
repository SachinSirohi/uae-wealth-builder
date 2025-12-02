import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_constants.dart';
import '../../services/background_service.dart';
import 'quick_setup_screen.dart';

class PermissionsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const PermissionsScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notifAccess = false;
  bool _smsAccess = false;
  bool _storageAccess = false;
  
  int _currentStep = 0;
  final int _totalSteps = 3;

  Future<void> _requestNotificationAccess() async {
    final status = await Permission.notification.request();
    setState(() {
      _notifAccess = status.isGranted;
      if (_notifAccess && _currentStep == 0) _currentStep = 1;
    });
  }

  Future<void> _requestSMSAccess() async {
    final status = await Permission.sms.request();
    setState(() {
      _smsAccess = status.isGranted;
      if (_smsAccess && _currentStep == 1) _currentStep = 2;
    });

    if (_smsAccess) {
      // Initialize background service now that we have permissions
      await BackgroundService.initialize();
      await BackgroundService.registerPeriodicTask();
    }
  }

  Future<void> _requestStorageAccess() async {
    final status = await Permission.storage.request();
    setState(() {
      _storageAccess = status.isGranted;
      if (_storageAccess && _currentStep == 2) _currentStep = 3;
    });
  }

  void _navigateToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuickSetupScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalSteps,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _currentStep
                          ? AppColors.success
                          : AppColors.cardBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Progress Text
              Text(
                'Step $_currentStep of $_totalSteps',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Title
              Text(
                'Grant Permissions',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              Text(
                'To automatically track your transactions,\nwe need a few permissions:',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              
              // Permission Cards
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      icon: Icons.notifications_active,
                      title: 'Notification Access',
                      description: 'Read bank notifications to auto-track transactions',
                      isGranted: _notifAccess,
                      onTap: _requestNotificationAccess,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    
                    _buildPermissionCard(
                      icon: Icons.sms,
                      title: 'SMS Permission',
                      description: 'Parse bank SMS for transaction details',
                      isGranted: _smsAccess,
                      onTap: _requestSMSAccess,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    
                    _buildPermissionCard(
                      icon: Icons.backup,
                      title: 'Google Drive Backup',
                      description: 'Encrypted backup to your private Google Drive',
                      isGranted: _storageAccess,
                      onTap: _requestStorageAccess,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Privacy Message
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Text(
                        'All data stays private on your phone',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              // Continue Button
              ElevatedButton(
                onPressed: _navigateToSetup,
                child: Text(
                  _currentStep >= _totalSteps ? 'All Set!' : 'Continue',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              TextButton(
                onPressed: _navigateToSetup,
                child: const Text('Skip Permissions', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isGranted ? AppColors.success : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Icon(
                isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isGranted ? AppColors.success : AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
