import 'package:google_fonts/google_fonts.dart';
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
  GoogleFonts.config.allowRuntimeFetching = false;

  Workmanager().initialize(
    callbackDispatcher,
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