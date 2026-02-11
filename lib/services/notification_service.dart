import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'prayer_time_service.dart';
import 'storage_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _iftarId = 1;
  static const _sahurId = 2;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: iOS);
    await _plugin.initialize(settings);

    // Request iOS permissions explicitly
    final iOSImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOSImpl != null) {
      final granted = await iOSImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      // ignore: avoid_print
      print('iOS notification permission granted: $granted');
    }

    // Also try macOS plugin for Darwin platforms
    final macOSImpl = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macOSImpl != null) {
      final granted = await macOSImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      // ignore: avoid_print
      print('macOS notification permission granted: $granted');
    }
  }

  static Future<void> scheduleIftarNotification(
    DateTime iftarTime, {
    int minutesBefore = 30,
  }) async {
    final scheduleTime = iftarTime.subtract(Duration(minutes: minutesBefore));
    if (scheduleTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);
    await _plugin.zonedSchedule(
      _iftarId,
      'VAKT',
      'İftara $minutesBefore dakika kaldı. Hazırlıklarınızı yapın.',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vakt_iftar',
          'İftar Bildirimi',
          channelDescription: 'İftar vakti hatırlatması',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleSahurNotification(
    DateTime sahurTime, {
    int minutesBefore = 45,
  }) async {
    final scheduleTime = sahurTime.subtract(Duration(minutes: minutesBefore));
    if (scheduleTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);
    await _plugin.zonedSchedule(
      _sahurId,
      'VAKT',
      'Sahura $minutesBefore dakika kaldı. Uyanma vakti.',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vakt_sahur',
          'Sahur Bildirimi',
          channelDescription: 'Sahur vakti hatırlatması',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleDailyNotifications(
      double lat, double lng) async {
    await cancelAll();

    final storage = StorageService();
    final prayerService = PrayerTimeService();
    final now = DateTime.now();
    final times = prayerService.getDailyPrayerTimes(lat, lng, now);

    final notifyIftar = storage.getSetting<bool>('notify_iftar') ?? true;
    final notifySahur = storage.getSetting<bool>('notify_sahur') ?? true;

    if (notifyIftar) {
      final maghrib = times['maghrib'];
      if (maghrib != null) {
        await scheduleIftarNotification(maghrib);
      }
    }

    if (notifySahur) {
      // Schedule for tomorrow's fajr
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes =
          prayerService.getDailyPrayerTimes(lat, lng, tomorrow);
      final fajr = tomorrowTimes['fajr'];
      if (fajr != null) {
        await scheduleSahurNotification(fajr);
      }
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
