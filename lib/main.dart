import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageService.init();
  } catch (e) {
    // ignore: avoid_print
    print('Storage init error: $e');
  }

  try {
    await NotificationService.init();
    // Schedule notifications on startup using cached location
    final storage = StorageService();
    final cached = storage.getLastLocation();
    final lat = (cached?['lat'] as num?)?.toDouble() ?? 41.0082;
    final lng = (cached?['lng'] as num?)?.toDouble() ?? 28.9784;
    await NotificationService.scheduleDailyNotifications(lat, lng);
    // ignore: avoid_print
    print('Notifications scheduled on app startup (lat=$lat, lng=$lng)');
  } catch (e) {
    // ignore: avoid_print
    print('Notification init error: $e');
  }

  runApp(const ProviderScope(child: VaktApp()));
}
