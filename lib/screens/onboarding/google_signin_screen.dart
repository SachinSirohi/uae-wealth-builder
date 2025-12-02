import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../constants/app_constants.dart';
import '../../services/google_drive_service.dart';
import 'permissions_screen.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  // Include Drive scope for backup functionality
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      drive.DriveApi.driveFileScope, // For backup files
    ],
  );

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null) {
        // Initialize Google Drive service with the signed-in account
        await GoogleDriveService.instance.initializeWithAccount(account);
        
        // Successfully signed in
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PermissionsScreen(
                userName: account.displayName ?? 'User',
                userEmail: account.email,
              ),
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to sign in. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _handleSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PermissionsScreen(
          userName: 'Guest',
          userEmail: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // UAE Skyline Icon
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppConstants.spacingL),
                
                // Title
                Text(
                  'Welcome to\nWealth Builder',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                
                // Subtitle
                Text(
                  'Track your UAE finances automatically\nwith complete privacy',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
                
                // Privacy Features
                _buildFeatureItem(
                  Icons.lock_outline,
                  '100% Private',
                  'All data stays on your device',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildFeatureItem(
                  Icons.notifications_none,
                  'Auto-Track',
                  'Parse SMS & notifications automatically',
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildFeatureItem(
                  Icons.trending_up,
                  'Maximize Wealth',
                  '40/20/40 UAE-optimized budget system',
                ),
                
                const Spacer(),
                
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                
                // Google Sign-In Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _isLoading ? 'Signing in...' : 'Continue with Google',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                
                // Skip Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _handleSkip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                
                // Privacy Note
                Text(
                  'We only use your name & email for personalization.\nNo data is shared with Google.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
