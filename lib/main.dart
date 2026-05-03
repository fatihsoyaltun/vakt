import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await StorageService.init();
      final storage = StorageService();
      final cached = storage.getLastLocation();
      final lat = (cached?['lat'] as num?)?.toDouble() ?? 41.0082;
      final lng = (cached?['lng'] as num?)?.toDouble() ?? 28.9784;

      await NotificationService.scheduleDailyNotifications(lat, lng);
    } catch (err) {
      // ignore: avoid_print
      print(err.toString());
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(callbackDispatcher);

  // For Android 14+ (S23 etc.), we ensure the daily sync logic uses a periodic task
  // that runs roughly once every day to refresh upcoming alarm schedules inside battery limits.
  Workmanager().registerPeriodicTask(
    'daily-notification-sync',
    'daily-notification-sync-task',
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(
      minutes: 15,
    ), // Avoid hitting it immediately on start
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow:
          true, // Sakin teknoloji: don't burn remaining battery
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  try {
    await StorageService.init();
  } catch (e) {
    // ignore: avoid_print
    print('Storage init error: $e');
  }

  try {
    await NotificationService.init();
    final storage = StorageService();
    final cached = storage.getLastLocation();
    final lat = (cached?['lat'] as num?)?.toDouble() ?? 41.0082;
    final lng = (cached?['lng'] as num?)?.toDouble() ?? 28.9784;
    await NotificationService.scheduleDailyNotifications(lat, lng);
  } catch (e) {
    // ignore: avoid_print
    print('Notification init error: $e');
  }

  runApp(const ProviderScope(child: VaktApp()));
}
