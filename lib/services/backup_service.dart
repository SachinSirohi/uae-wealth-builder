import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'google_drive_service.dart';

/// Backup and restore service for Google Drive integration
class BackupService {
  static const String _encryptionKey = 'UAEWealthBuilder2024SecretKey32!'; // 32 chars for AES-256
  static const String _lastLocalBackupKey = 'last_local_backup';
  static const String _lastCloudBackupKey = 'last_cloud_backup';

  static final GoogleDriveService _driveService = GoogleDriveService.instance;

  /// Serialize all data to encrypted JSON
  static Future<Uint8List> createBackup() async {
    try {
      final transactionsBox = Hive.box<Transaction>('transactions');
      final settingsBox = Hive.box<UserSettings>('settings');

      // Collect all transactions
      final transactions = transactionsBox.values.map((t) => {
        'id': t.id,
        'date': t.date.toIso8601String(),
        'amount': t.amount,
        'description': t.description,
        'merchant': t.merchant,
        'rawText': t.rawText,
        'category': t.category.index,
        'confirmed': t.confirmed,
        'isIncome': t.isIncome,
      }).toList();

      // Collect settings
      final settings = settingsBox.get('user_settings');
      final settingsMap = settings != null
          ? {
              'name': settings.name,
              'email': settings.email,
              'monthlySalary': settings.monthlySalary,
              'emergencyFundGoal': settings.emergencyFundGoal,
              'budgetAllocations': settings.budgetAllocations,
              'currency': settings.currency,
              'biometricEnabled': settings.biometricEnabled,
              'backupEnabled': settings.backupEnabled,
              'lastBackupDate': settings.lastBackupDate?.toIso8601String(),
              'customRules': settings.customRules,
              'autoBackupEnabled': settings.autoBackupEnabled,
              'notificationsEnabled': settings.notificationsEnabled,
            }
          : null;

      // Create backup data
      final backupData = {
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'transactions': transactions,
        'settings': settingsMap,
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Encrypt the data
      final encryptedData = _encryptData(jsonString);

      return encryptedData;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Restore data from encrypted backup
  static Future<bool> restoreBackup(Uint8List encryptedData) async {
    try {
      // Decrypt the data
      final jsonString = _decryptData(encryptedData);

      // Parse JSON
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Verify version
      final version = backupData['version'] as int;
      if (version != 1) {
        throw Exception('Unsupported backup version: $version');
      }

      // Clear existing data
      final transactionsBox = Hive.box<Transaction>('transactions');
      final settingsBox = Hive.box<UserSettings>('settings');
      await transactionsBox.clear();
      await settingsBox.clear();

      // Restore transactions
      final transactions = backupData['transactions'] as List<dynamic>;
      for (var t in transactions) {
        final transaction = Transaction(
          id: t['id'],
          date: DateTime.parse(t['date']),
          amount: t['amount'],
          description: t['description'],
          merchant: t['merchant'] ?? '',
          rawText: t['rawText'] ?? '',
          category: TransactionCategory.values[t['category']],
          confirmed: t['confirmed'] ?? false,
          isIncome: t['isIncome'],
        );
        await transactionsBox.put(transaction.id, transaction);
      }

      // Restore settings
      final settingsMap = backupData['settings'] as Map<String, dynamic>?;
      if (settingsMap != null) {
        final settings = UserSettings(
          name: settingsMap['name'] ?? '',
          email: settingsMap['email'] ?? '',
          monthlySalary: settingsMap['monthlySalary'] ?? 10000.0,
          emergencyFundGoal: settingsMap['emergencyFundGoal'],
          budgetAllocations: Map<String, double>.from(settingsMap['budgetAllocations'] ?? {}),
          currency: settingsMap['currency'] ?? 'AED',
          biometricEnabled: settingsMap['biometricEnabled'] ?? false,
          backupEnabled: settingsMap['backupEnabled'] ?? false,
          customRules: Map<String, String>.from(settingsMap['customRules'] ?? {}),
          autoBackupEnabled: settingsMap['autoBackupEnabled'],
          notificationsEnabled: settingsMap['notificationsEnabled'],
        );
        if (settingsMap['lastBackupDate'] != null) {
          settings.lastBackupDate = DateTime.parse(settingsMap['lastBackupDate']);
        }
        await settingsBox.put('user_settings', settings);
      }

      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }

  /// Encrypt data using AES-256
  static Uint8List _encryptData(String data) {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);
    
    // Combine IV and encrypted data
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);
    
    return combined;
  }

  /// Decrypt data using AES-256
  static String _decryptData(Uint8List encryptedData) {
    final key = encrypt.Key.fromUtf8(_encryptionKey);
    
    // Extract IV from the beginning
    final iv = encrypt.IV(encryptedData.sublist(0, 16));
    final encrypted = encrypt.Encrypted(encryptedData.sublist(16));
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    
    return decrypted;
  }

  /// Get backup file name with timestamp
  static String getBackupFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'wealth_builder_backup_$timestamp.bak';
  }

  /// Validate backup file
  static Future<BackupInfo?> validateBackup(Uint8List encryptedData) async {
    try {
      final jsonString = _decryptData(encryptedData);
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      return BackupInfo(
        version: backupData['version'] as int,
        createdAt: DateTime.parse(backupData['createdAt']),
        transactionCount: (backupData['transactions'] as List).length,
        hasSettings: backupData['settings'] != null,
      );
    } catch (e) {
      debugPrint('Invalid backup file: $e');
      return null;
    }
  }
}

/// Backup file information
class BackupInfo {
  final int version;
  final DateTime createdAt;
  final int transactionCount;
  final bool hasSettings;

  BackupInfo({
    required this.version,
    required this.createdAt,
    required this.transactionCount,
    required this.hasSettings,
  });
}

/// Integrated Google Drive backup operations
class CloudBackupManager {
  static final GoogleDriveService _driveService = GoogleDriveService.instance;

  /// Check if user is signed in with Google
  static bool get isAuthenticated => _driveService.isAuthenticated;

  /// Get signed-in user email
  static String? get userEmail => _driveService.userEmail;

  /// Create and upload backup to Google Drive
  static Future<CloudBackupResult> backupToCloud() async {
    try {
      if (!_driveService.isAuthenticated) {
        return CloudBackupResult(
          success: false,
          error: 'Not signed in with Google. Please sign in first.',
        );
      }

      // Create encrypted backup
      final backupData = await BackupService.createBackup();
      final fileName = BackupService.getBackupFileName();

      // Upload to Google Drive
      final uploadResult = await _driveService.uploadBackup(backupData, fileName);

      if (!uploadResult.success) {
        return CloudBackupResult(
          success: false,
          error: uploadResult.error ?? 'Upload failed',
        );
      }

      // Update settings with last backup date
      await _updateLastBackupDate();

      // Cleanup old backups (keep last 5)
      await _driveService.cleanupOldBackups(keepCount: 5);

      // Save last cloud backup time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_cloud_backup', DateTime.now().toIso8601String());

      return CloudBackupResult(
        success: true,
        fileName: uploadResult.fileName,
        fileId: uploadResult.fileId,
      );
    } catch (e) {
      debugPrint('Cloud backup error: $e');
      return CloudBackupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Restore backup from Google Drive
  static Future<CloudRestoreResult> restoreFromCloud(String fileId) async {
    try {
      if (!_driveService.isAuthenticated) {
        return CloudRestoreResult(
          success: false,
          error: 'Not signed in with Google',
        );
      }

      // Download from Google Drive
      final downloadResult = await _driveService.downloadBackup(fileId);

      if (!downloadResult.success || downloadResult.data == null) {
        return CloudRestoreResult(
          success: false,
          error: downloadResult.error ?? 'Download failed',
        );
      }

      // Validate backup
      final backupInfo = await BackupService.validateBackup(downloadResult.data!);
      if (backupInfo == null) {
        return CloudRestoreResult(
          success: false,
          error: 'Invalid or corrupted backup file',
        );
      }

      // Restore backup
      final restored = await BackupService.restoreBackup(downloadResult.data!);

      if (!restored) {
        return CloudRestoreResult(
          success: false,
          error: 'Failed to restore backup data',
        );
      }

      return CloudRestoreResult(
        success: true,
        transactionsRestored: backupInfo.transactionCount,
        backupDate: backupInfo.createdAt,
      );
    } catch (e) {
      debugPrint('Cloud restore error: $e');
      return CloudRestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// List available backups from Google Drive
  static Future<List<DriveBackupFile>> listCloudBackups() async {
    return await _driveService.listBackups();
  }

  /// Delete a backup from Google Drive
  static Future<bool> deleteCloudBackup(String fileId) async {
    return await _driveService.deleteBackup(fileId);
  }

  /// Get last cloud backup time
  static Future<DateTime?> getLastCloudBackupTime() async {
    return await _driveService.getLastSyncTime();
  }

  /// Get storage usage info
  static Future<DriveStorageInfo> getStorageUsage() async {
    return await _driveService.getStorageUsage();
  }

  /// Get auto-backup frequency
  static Future<BackupFrequency> getAutoBackupFrequency() async {
    return await _driveService.getAutoBackupFrequency();
  }

  /// Set auto-backup frequency
  static Future<void> setAutoBackupFrequency(BackupFrequency frequency) async {
    await _driveService.setAutoBackupFrequency(frequency);
  }

  /// Check if auto-backup is due
  static Future<bool> isAutoBackupDue() async {
    final frequency = await getAutoBackupFrequency();
    if (frequency == BackupFrequency.never) return false;

    final lastBackup = await getLastCloudBackupTime();
    if (lastBackup == null) return true; // Never backed up

    final duration = frequency.duration;
    if (duration == null) return false;

    return DateTime.now().difference(lastBackup) >= duration;
  }

  /// Perform auto-backup if due
  static Future<CloudBackupResult?> performAutoBackupIfDue() async {
    // TODO: Implement connectivity check
    // if (!isConnected) return null;

    final isDue = await isAutoBackupDue();
    if (!isDue) return null;

    debugPrint('Auto-backup is due, performing backup...');
    return await backupToCloud();
  }

  static Future<void> _updateLastBackupDate() async {
    try {
      final settingsBox = Hive.box<UserSettings>('settings');
      final settings = settingsBox.get('user_settings');
      if (settings != null) {
        settings.lastBackupDate = DateTime.now();
        await settingsBox.put('user_settings', settings);
      }
    } catch (e) {
      debugPrint('Error updating last backup date: $e');
    }
  }
}

/// Result of cloud backup operation
class CloudBackupResult {
  final bool success;
  final String? fileName;
  final String? fileId;
  final String? error;

  CloudBackupResult({
    required this.success,
    this.fileName,
    this.fileId,
    this.error,
  });
}

/// Result of cloud restore operation
class CloudRestoreResult {
  final bool success;
  final int? transactionsRestored;
  final DateTime? backupDate;
  final String? error;

  CloudRestoreResult({
    required this.success,
    this.transactionsRestored,
    this.backupDate,
    this.error,
  });
}

