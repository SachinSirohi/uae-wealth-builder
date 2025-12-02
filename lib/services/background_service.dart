import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:telephony/telephony.dart' hide NetworkType;
import '../models/transaction.dart';
import '../models/user_settings.dart';
import 'sms_parser_service.dart';

const String taskName = 'smsSyncTask';

/// Top-level function for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == taskName) {
        await _handleBackgroundSync();
      }
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Main background sync logic
Future<void> _handleBackgroundSync() async {
  // Initialize Hive for background isolate
  if (!Hive.isAdapterRegistered(0)) {
    Hive.initFlutter();
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionCategoryAdapter());
    Hive.registerAdapter(BudgetTypeAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
  }

  // Open boxes
  final transactionsBox = await Hive.openBox<Transaction>('transactions');
  
  // Get SMS messages
  final Telephony telephony = Telephony.instance;
  bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
  
  if (permissionsGranted != true) {
    return;
  }

  // Get last sync time (store in shared prefs or Hive)
  // For now, we'll scan last 24 hours to be safe
  final DateTime now = DateTime.now();
  final DateTime lastSync = now.subtract(const Duration(hours: 24));

  // Fetch SMS
  List<SmsMessage> messages = await telephony.getInboxSms(
    columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    filter: SmsFilter.where(SmsColumn.DATE).greaterThan(lastSync.millisecondsSinceEpoch.toString()),
  );

  int newTransactionsCount = 0;

  for (var msg in messages) {
    if (msg.body == null || msg.address == null) continue;

    // Parse SMS
    final transaction = SMSParserService.parseSMS(
      msg.body!,
      msg.address!,
      DateTime.fromMillisecondsSinceEpoch(msg.date ?? now.millisecondsSinceEpoch),
    );

    if (transaction != null) {
      // Check if already exists (deduplication)
      // Simple check: same amount, merchant, and date within 1 minute
      bool exists = transactionsBox.values.any((t) =>
          t.amount == transaction.amount &&
          t.merchant == transaction.merchant &&
          t.date.difference(transaction.date).inMinutes.abs() < 1);

      if (!exists) {
        await transactionsBox.put(transaction.id, transaction);
        newTransactionsCount++;
      }
    }
  }

  // Show notification if new transactions found
  if (newTransactionsCount > 0) {
    await _showNotification(newTransactionsCount);
  }
}

Future<void> _showNotification(int count) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'wealth_builder_channel',
    'Wealth Builder Updates',
    channelDescription: 'Notifications for new transactions',
    importance: Importance.low,
    priority: Priority.low,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'New Transactions Tracked',
    '$count new transactions added to your dashboard',
    platformChannelSpecifics,
  );
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set true for testing
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(minutes: 15), // Minimum 15 min on Android
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
