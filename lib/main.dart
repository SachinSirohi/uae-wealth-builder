import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants/app_constants.dart';
import 'models/transaction.dart';
import 'models/user_settings.dart';
import 'screens/splash_screen.dart';
import 'services/auto_backup_scheduler.dart';
import 'services/google_drive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionCategoryAdapter());
  Hive.registerAdapter(BudgetTypeAdapter());
  Hive.registerAdapter(UserSettingsAdapter());

  // Open boxes
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<UserSettings>('settings');

  // Initialize Auto-Backup Scheduler
  await AutoBackupScheduler.initialize();

  // Try to restore Google Drive session silently (uses existing sign-in)
  await GoogleDriveService.instance.tryRestoreSession();

  // Initialize Background Service
  // Note: This requires Android permissions to be granted first
  // We'll initialize it here, but the task registration should happen after permissions
  // await BackgroundService.initialize();

  runApp(const PersonalFinanceApp());
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Wealth Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.heading1,
          displayMedium: AppTextStyles.heading2,
          displaySmall: AppTextStyles.heading3,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          labelLarge: AppTextStyles.label,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
