import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';
import '../../services/auto_backup_scheduler.dart';

/// Google Drive Backup Screen
/// User is already authenticated via Google Sign-In during onboarding
/// This screen just manages backup operations
class GoogleDriveBackupScreen extends StatefulWidget {
  const GoogleDriveBackupScreen({super.key});

  @override
  State<GoogleDriveBackupScreen> createState() => _GoogleDriveBackupScreenState();
}

class _GoogleDriveBackupScreenState extends State<GoogleDriveBackupScreen> {
  final GoogleDriveService _driveService = GoogleDriveService.instance;
  
  bool _isLoading = false;
  DateTime? _lastBackup;
  BackupFrequency _autoBackupFrequency = BackupFrequency.never;
  List<DriveBackupFile> _backups = [];
  DriveStorageInfo? _storageInfo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Try to restore session if not already authenticated
    if (!_driveService.isAuthenticated) {
      await _driveService.tryRestoreSession();
    }
    
    await _refreshStatus();
    
    setState(() => _isLoading = false);
  }

  Future<void> _refreshStatus() async {
    if (_driveService.isAuthenticated) {
      final lastBackup = await CloudBackupManager.getLastCloudBackupTime();
      final frequency = await CloudBackupManager.getAutoBackupFrequency();
      final backups = await CloudBackupManager.listCloudBackups();
      final storageInfo = await CloudBackupManager.getStorageUsage();

      setState(() {
        _lastBackup = lastBackup;
        _autoBackupFrequency = frequency;
        _backups = backups;
        _storageInfo = storageInfo;
      });
    }
  }

  Future<void> _backupNow() async {
    if (!_driveService.isAuthenticated) {
      _showNotSignedInMessage();
      return;
    }

    setState(() => _isLoading = true);

    final result = await CloudBackupManager.backupToCloud();

    if (result.success) {
      await _refreshStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Backup failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _showNotSignedInMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in with Google to use backup features'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _restoreBackup(DriveBackupFile backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will replace all current data with the backup. '
              'This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Created: ${DateFormat('MMM d, y h:mm a').format(backup.createdAt)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text('Size: ${backup.formattedSize}', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await CloudBackupManager.restoreFromCloud(backup.id);

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${result.transactionsRestored} transactions successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Restore failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteBackup(DriveBackupFile backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: Text('Delete "${backup.name}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final deleted = await CloudBackupManager.deleteCloudBackup(backup.id);
      if (deleted) {
        await _refreshStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup deleted')),
          );
        }
      }
    }
  }

  Future<void> _showFrequencyPicker() async {
    final selected = await showDialog<BackupFrequency>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Auto-Backup Frequency'),
        children: BackupFrequency.values.map((frequency) {
          return RadioListTile<BackupFrequency>(
            title: Text(frequency.displayName),
            subtitle: frequency != BackupFrequency.never
                ? Text(_getFrequencyDescription(frequency))
                : null,
            value: frequency,
            groupValue: _autoBackupFrequency,
            activeColor: AppColors.primary,
            onChanged: (value) => Navigator.pop(context, value),
          );
        }).toList(),
      ),
    );

    if (selected != null && selected != _autoBackupFrequency) {
      await CloudBackupManager.setAutoBackupFrequency(selected);
      await AutoBackupScheduler.scheduleAutoBackup(selected);
      setState(() => _autoBackupFrequency = selected);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selected == BackupFrequency.never
                  ? 'Auto-backup disabled'
                  : 'Auto-backup set to ${selected.displayName.toLowerCase()}',
            ),
          ),
        );
      }
    }
  }

  String _getFrequencyDescription(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Backup every 24 hours';
      case BackupFrequency.weekly:
        return 'Backup every 7 days';
      case BackupFrequency.monthly:
        return 'Backup every 30 days';
      case BackupFrequency.never:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _driveService.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Backup'),
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _refreshStatus,
            ),
        ],
      ),
      body: _isLoading && !isAuthenticated
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              children: [
                // Account Status Card
                _buildAccountCard(),
                const SizedBox(height: AppConstants.spacingL),

                if (isAuthenticated) ...[
                  // Quick Actions
                  _buildQuickActionsCard(),
                  const SizedBox(height: AppConstants.spacingL),

                  // Auto-Backup Settings
                  _buildAutoBackupCard(),
                  const SizedBox(height: AppConstants.spacingL),

                  // Backup List
                  _buildBackupListCard(),
                  const SizedBox(height: AppConstants.spacingL),

                  // Storage Info
                  if (_storageInfo != null) _buildStorageInfoCard(),
                ] else ...[
                  _buildNotSignedInCard(),
                ],
              ],
            ),
    );
  }

  Widget _buildAccountCard() {
    final isAuthenticated = _driveService.isAuthenticated;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isAuthenticated ? Colors.green.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_to_drive,
                size: 24,
                color: isAuthenticated ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAuthenticated ? 'Connected' : 'Not Connected',
                    style: AppTextStyles.heading3,
                  ),
                  if (isAuthenticated && _driveService.userEmail != null)
                    Text(
                      _driveService.userEmail!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isAuthenticated ? Icons.check_circle : Icons.error_outline,
              color: isAuthenticated ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSignedInCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Sign in with Google to backup',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'To use Google Drive backup, please sign in with your Google account from the app settings or during onboarding.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_upload, color: AppColors.primary),
            ),
            title: const Text('Backup Now'),
            subtitle: _lastBackup != null
                ? Text('Last: ${_formatLastBackup(_lastBackup!)}')
                : const Text('Never backed up'),
            trailing: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isLoading ? null : _backupNow,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoBackupCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.textSecondary),
                const SizedBox(width: AppConstants.spacingS),
                const Text(
                  'Auto-Backup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Backup Frequency'),
            subtitle: Text(_autoBackupFrequency.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showFrequencyPicker,
          ),
          if (_autoBackupFrequency != BackupFrequency.never) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      'Backups run automatically when connected to Wi-Fi and battery is not low',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupListCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Icon(Icons.history, color: AppColors.textSecondary),
                const SizedBox(width: AppConstants.spacingS),
                const Text(
                  'Available Backups',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_backups.length} backup${_backups.length != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_backups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'No backups yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _backups.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final backup = _backups[index];
                return ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(
                    backup.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${backup.formattedDate} • ${backup.formattedSize}',
                  ),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore),
                            SizedBox(width: 8),
                            Text('Restore'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (action) {
                      if (action == 'restore') {
                        _restoreBackup(backup);
                      } else if (action == 'delete') {
                        _deleteBackup(backup);
                      }
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStorageInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storage, color: AppColors.secondary),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Storage Used',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_storageInfo!.totalBackups} backups • ${_storageInfo!.formattedSize}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
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

  String _formatLastBackup(DateTime lastBackup) {
    final diff = DateTime.now().difference(lastBackup);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(lastBackup);
  }
}
