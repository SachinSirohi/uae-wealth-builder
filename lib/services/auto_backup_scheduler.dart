import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import 'backup_service.dart';
import 'google_drive_service.dart';

/// Unique task names for workmanager
const String autoBackupTaskName = 'com.wealthbuilder.autobackup';
const String periodicBackupTaskName = 'com.wealthbuilder.periodicbackup';

/// Auto-backup scheduler using WorkManager for background execution
class AutoBackupScheduler {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the workmanager and notifications
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
  }

  /// Schedule periodic backup based on user preference
  static Future<void> scheduleAutoBackup(BackupFrequency frequency) async {
    // Cancel existing scheduled tasks
    await Workmanager().cancelByUniqueName(periodicBackupTaskName);

    if (frequency == BackupFrequency.never) {
      debugPrint('Auto-backup disabled');
      return;
    }

    // Get frequency duration
    Duration? period;
    switch (frequency) {
      case BackupFrequency.daily:
        period = const Duration(hours: 24);
        break;
      case BackupFrequency.weekly:
        period = const Duration(days: 7);
        break;
      case BackupFrequency.monthly:
        period = const Duration(days: 30);
        break;
      case BackupFrequency.never:
        return;
    }

    // Schedule periodic task
    await Workmanager().registerPeriodicTask(
      periodicBackupTaskName,
      autoBackupTaskName,
      frequency: period,
      constraints: Constraints(
        networkType: NetworkType.connected, // Require network
        requiresBatteryNotLow: true, // Don't run on low battery
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
      inputData: {
        'frequency': frequency.index,
      },
    );

    debugPrint('Scheduled auto-backup: ${frequency.displayName}');
  }

  /// Run one-time backup task immediately
  static Future<void> runBackupNow() async {
    await Workmanager().registerOneOffTask(
      '${autoBackupTaskName}_${DateTime.now().millisecondsSinceEpoch}',
      autoBackupTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Cancel all scheduled backups
  static Future<void> cancelAllBackups() async {
    await Workmanager().cancelByUniqueName(periodicBackupTaskName);
    debugPrint('Cancelled all scheduled backups');
  }

  /// Show backup notification
  static Future<void> showBackupNotification({
    required String title,
    required String body,
    bool isError = false,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Notifications',
      channelDescription: 'Notifications for backup status',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      isError ? 2 : 1,
      title,
      body,
      details,
    );
  }
}

/// Top-level callback for WorkManager - must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('Background task started: $taskName');

    try {
      if (taskName == autoBackupTaskName) {
        return await _performBackgroundBackup();
      }
      return true;
    } catch (e) {
      debugPrint('Background task error: $e');
      return false;
    }
  });
}

/// Perform the actual backup in background
Future<bool> _performBackgroundBackup() async {
  try {
    // Initialize Hive for background isolate
    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }

    // Open required boxes
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<UserSettings>('settings');

    // Try to restore Google Drive session
    final driveService = GoogleDriveService.instance;
    final authenticated = await driveService.tryRestoreSession();

    if (!authenticated) {
      debugPrint('Could not restore Google session for background backup');
      await AutoBackupScheduler.showBackupNotification(
        title: 'Backup Skipped',
        body: 'Please sign in with Google to enable auto-backup',
        isError: true,
      );
      return false;
    }

    // Perform backup
    final result = await CloudBackupManager.backupToCloud();

    if (result.success) {
      debugPrint('Background backup successful: ${result.fileName}');
      await AutoBackupScheduler.showBackupNotification(
        title: 'Backup Complete',
        body: 'Your financial data has been backed up to Google Drive',
      );
      return true;
    } else {
      debugPrint('Background backup failed: ${result.error}');
      await AutoBackupScheduler.showBackupNotification(
        title: 'Backup Failed',
        body: result.error ?? 'Unknown error occurred',
        isError: true,
      );
      return false;
    }
  } catch (e) {
    debugPrint('Background backup error: $e');
    await AutoBackupScheduler.showBackupNotification(
      title: 'Backup Error',
      body: 'Failed to backup: ${e.toString()}',
      isError: true,
    );
    return false;
  }
}

/// Backup status for UI display
class BackupStatus {
  final bool isAuthenticated;
  final String? userEmail;
  final DateTime? lastBackupTime;
  final BackupFrequency frequency;
  final int? totalBackups;
  final String? storageUsed;

  BackupStatus({
    required this.isAuthenticated,
    this.userEmail,
    this.lastBackupTime,
    required this.frequency,
    this.totalBackups,
    this.storageUsed,
  });

  /// Get a human-readable status string
  String get statusText {
    if (!isAuthenticated) return 'Not signed in';
    if (lastBackupTime == null) return 'Never backed up';

    final diff = DateTime.now().difference(lastBackupTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${lastBackupTime!.day}/${lastBackupTime!.month}/${lastBackupTime!.year}';
  }

  /// Get next backup time estimate
  String? get nextBackupText {
    if (!isAuthenticated || frequency == BackupFrequency.never) return null;
    if (lastBackupTime == null) return 'Pending';

    final duration = frequency.duration;
    if (duration == null) return null;

    final nextBackup = lastBackupTime!.add(duration);
    final diff = nextBackup.difference(DateTime.now());

    if (diff.isNegative) return 'Soon';
    if (diff.inHours < 1) return 'In ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'In ${diff.inHours}h';
    return 'In ${diff.inDays}d';
  }

  /// Load current backup status
  static Future<BackupStatus> load() async {
    final driveService = GoogleDriveService.instance;
    final isAuthenticated = driveService.isAuthenticated;

    DateTime? lastBackup;
    int? totalBackups;
    String? storageUsed;

    if (isAuthenticated) {
      lastBackup = await CloudBackupManager.getLastCloudBackupTime();
      final storageInfo = await CloudBackupManager.getStorageUsage();
      totalBackups = storageInfo.totalBackups;
      storageUsed = storageInfo.formattedSize;
    }

    final frequency = await CloudBackupManager.getAutoBackupFrequency();

    return BackupStatus(
      isAuthenticated: isAuthenticated,
      userEmail: driveService.userEmail,
      lastBackupTime: lastBackup,
      frequency: frequency,
      totalBackups: totalBackups,
      storageUsed: storageUsed,
    );
  }
}
