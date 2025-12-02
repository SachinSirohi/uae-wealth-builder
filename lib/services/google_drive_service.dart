import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Google Drive integration service for backup/restore functionality
/// Uses the existing Google Sign-In authentication (no separate connection needed)
class GoogleDriveService {
  static const String _appFolderName = 'WealthBuilderBackups';
  static const String _lastSyncKey = 'last_google_drive_sync';
  static const String _autoBackupFrequencyKey = 'auto_backup_frequency';

  static GoogleDriveService? _instance;
  static GoogleDriveService get instance => _instance ??= GoogleDriveService._();

  GoogleDriveService._();

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  String? _appFolderId;

  /// Check if user is authenticated with Google (from initial sign-in)
  bool get isAuthenticated => _currentUser != null && _driveApi != null;

  /// Get current user email
  String? get userEmail => _currentUser?.email;

  /// Get current user display name
  String? get userName => _currentUser?.displayName;

  /// Get current user photo URL
  String? get userPhotoUrl => _currentUser?.photoUrl;

  /// Initialize with an already signed-in Google account
  /// Called during onboarding after Google Sign-In
  Future<void> initializeWithAccount(GoogleSignInAccount account) async {
    try {
      _currentUser = account;
      
      final googleAuth = await account.authentication;
      final authClient = _GoogleAuthClient(accessToken: googleAuth.accessToken!);
      
      _driveApi = drive.DriveApi(authClient);
      await _getOrCreateAppFolder();
      
      debugPrint('Google Drive initialized for: ${account.email}');
    } catch (e) {
      debugPrint('Failed to initialize Google Drive: $e');
      _currentUser = null;
      _driveApi = null;
    }
  }

  /// Try to restore session from existing Google Sign-In
  /// Called on app startup
  Future<bool> tryRestoreSession() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          drive.DriveApi.driveFileScope,
        ],
      );

      // Try silent sign-in (uses cached credentials)
      final account = await googleSignIn.signInSilently();
      
      if (account != null) {
        await initializeWithAccount(account);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Failed to restore Google session: $e');
      return false;
    }
  }

  /// Get or create the app's backup folder in Google Drive
  Future<void> _getOrCreateAppFolder() async {
    if (_driveApi == null) return;

    try {
      // Search for existing folder
      final folderList = await _driveApi!.files.list(
        q: "name = '$_appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        _appFolderId = folderList.files!.first.id;
        debugPrint('Found existing backup folder: $_appFolderId');
      } else {
        // Create new folder
        final folder = drive.File()
          ..name = _appFolderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        _appFolderId = createdFolder.id;
        debugPrint('Created new backup folder: $_appFolderId');
      }
    } catch (e) {
      debugPrint('Error with backup folder: $e');
      rethrow;
    }
  }

  /// Upload backup data to Google Drive
  Future<DriveUploadResult> uploadBackup(Uint8List data, String fileName) async {
    if (!isAuthenticated || _appFolderId == null) {
      return DriveUploadResult(
        success: false,
        error: 'Not signed in with Google. Please sign in first.',
      );
    }

    try {
      // Check for existing file with same name and delete it
      final existingFiles = await _driveApi!.files.list(
        q: "name = '$fileName' and '$_appFolderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        for (var file in existingFiles.files!) {
          await _driveApi!.files.delete(file.id!);
        }
      }

      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_appFolderId!]
        ..mimeType = 'application/octet-stream'
        ..description = 'Wealth Builder backup - ${DateTime.now().toIso8601String()}';

      // Upload file
      final media = drive.Media(
        Stream.value(data),
        data.length,
      );

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, size, createdTime',
      );

      // Save last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint('Uploaded backup: ${uploadedFile.name} (${uploadedFile.id})');

      return DriveUploadResult(
        success: true,
        fileId: uploadedFile.id,
        fileName: uploadedFile.name,
      );
    } catch (e) {
      debugPrint('Upload error: $e');
      return DriveUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Download backup from Google Drive
  Future<DriveDownloadResult> downloadBackup(String fileId) async {
    if (!isAuthenticated) {
      return DriveDownloadResult(
        success: false,
        error: 'Not signed in with Google',
      );
    }

    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (response is drive.Media) {
        final List<int> bytes = [];
        await for (var chunk in response.stream) {
          bytes.addAll(chunk);
        }

        return DriveDownloadResult(
          success: true,
          data: Uint8List.fromList(bytes),
        );
      }

      return DriveDownloadResult(
        success: false,
        error: 'Invalid response from Drive',
      );
    } catch (e) {
      debugPrint('Download error: $e');
      return DriveDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// List all backups in the app folder
  Future<List<DriveBackupFile>> listBackups() async {
    if (!isAuthenticated || _appFolderId == null) {
      return [];
    }

    try {
      final fileList = await _driveApi!.files.list(
        q: "'$_appFolderId' in parents and trashed = false",
        spaces: 'drive',
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, size, createdTime, modifiedTime)',
      );

      if (fileList.files == null) return [];

      return fileList.files!.map((file) {
        return DriveBackupFile(
          id: file.id ?? '',
          name: file.name ?? 'Unknown',
          createdAt: file.createdTime ?? DateTime.now(),
          size: int.tryParse(file.size ?? '0') ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('List backups error: $e');
      return [];
    }
  }

  /// Delete a backup from Google Drive
  Future<bool> deleteBackup(String fileId) async {
    if (!isAuthenticated) return false;

    try {
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Delete backup error: $e');
      return false;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    if (lastSync == null) return null;
    return DateTime.tryParse(lastSync);
  }

  /// Get storage usage in the app folder
  Future<DriveStorageInfo> getStorageUsage() async {
    if (!isAuthenticated) {
      return DriveStorageInfo(totalBackups: 0, totalSizeBytes: 0);
    }

    try {
      final backups = await listBackups();
      int totalSize = 0;
      for (var backup in backups) {
        totalSize += backup.size;
      }

      return DriveStorageInfo(
        totalBackups: backups.length,
        totalSizeBytes: totalSize,
      );
    } catch (e) {
      return DriveStorageInfo(totalBackups: 0, totalSizeBytes: 0);
    }
  }

  /// Auto-backup frequency settings
  Future<BackupFrequency> getAutoBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final frequencyIndex = prefs.getInt(_autoBackupFrequencyKey) ?? 0;
    return BackupFrequency.values[frequencyIndex.clamp(0, BackupFrequency.values.length - 1)];
  }

  Future<void> setAutoBackupFrequency(BackupFrequency frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoBackupFrequencyKey, frequency.index);
  }

  /// Clean up old backups, keeping only the most recent ones
  Future<int> cleanupOldBackups({int keepCount = 5}) async {
    if (!isAuthenticated) return 0;

    try {
      final backups = await listBackups();
      if (backups.length <= keepCount) return 0;

      int deletedCount = 0;
      for (int i = keepCount; i < backups.length; i++) {
        final deleted = await deleteBackup(backups[i].id);
        if (deleted) deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      debugPrint('Cleanup error: $e');
      return 0;
    }
  }
}

/// HTTP client for Google API authentication
class _GoogleAuthClient extends http.BaseClient {
  final String accessToken;
  final http.Client _client = http.Client();

  _GoogleAuthClient({required this.accessToken});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return _client.send(request);
  }
}

/// Result of upload operation
class DriveUploadResult {
  final bool success;
  final String? fileId;
  final String? fileName;
  final String? error;

  DriveUploadResult({
    required this.success,
    this.fileId,
    this.fileName,
    this.error,
  });
}

/// Result of download operation
class DriveDownloadResult {
  final bool success;
  final Uint8List? data;
  final String? error;

  DriveDownloadResult({
    required this.success,
    this.data,
    this.error,
  });
}

/// Backup file info from Google Drive
class DriveBackupFile {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;

  DriveBackupFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

/// Drive storage info
class DriveStorageInfo {
  final int totalBackups;
  final int totalSizeBytes;

  DriveStorageInfo({
    required this.totalBackups,
    required this.totalSizeBytes,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Auto-backup frequency options
enum BackupFrequency {
  never,
  daily,
  weekly,
  monthly,
}

extension BackupFrequencyExtension on BackupFrequency {
  String get displayName {
    switch (this) {
      case BackupFrequency.never:
        return 'Never';
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }

  Duration? get duration {
    switch (this) {
      case BackupFrequency.never:
        return null;
      case BackupFrequency.daily:
        return const Duration(days: 1);
      case BackupFrequency.weekly:
        return const Duration(days: 7);
      case BackupFrequency.monthly:
        return const Duration(days: 30);
    }
  }
}
