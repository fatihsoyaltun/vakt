import 'dart:io';

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

    // Hatanın çözümü: Parametre adı 'settings' olarak güncellendi.
    await _plugin.initialize(settings: settings);

    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
  }

  static Future<void> _requestAndroidPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) return;

    final notifGranted = await androidImpl.requestNotificationsPermission();
    // ignore: avoid_print
    print('Android POST_NOTIFICATIONS permission granted: $notifGranted');

    final alarmGranted = await androidImpl.requestExactAlarmsPermission();
    // ignore: avoid_print
    print('Android SCHEDULE_EXACT_ALARM permission granted: $alarmGranted');
  }

  static Future<void> _requestIOSPermissions() async {
    final iOSImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iOSImpl != null) {
      final granted = await iOSImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      // ignore: avoid_print
      print('iOS notification permission granted: $granted');
    }
  }

  static Future<void> scheduleIftarNotification(
    DateTime iftarTime, {
    int minutesBefore = 30,
  }) async {
    final scheduleTime = iftarTime.subtract(Duration(minutes: minutesBefore));
    if (scheduleTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);
    // ignore: avoid_print
    print('Scheduling iftar notification for: $iftarTime (alert at $tzTime)');
    try {
      await _plugin.zonedSchedule(
        id: _iftarId,
        title: 'VAKT',
        body: 'İftara $minutesBefore dakika kaldı. Hazırlıklarınızı yapın.',
        scheduledDate: tzTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'vakt_iftar',
            'İftar Bildirimi',
            channelDescription: 'İftar vakti hatırlatması',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory
                .alarm, // Important for battery overrides
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      // ignore: avoid_print
      print('Iftar notification scheduled successfully');
    } catch (e) {
      // ignore: avoid_print
      print('NOTIFICATION ERROR (iftar): $e');
    }
  }

  static Future<void> scheduleSahurNotification(
    DateTime sahurTime, {
    int minutesBefore = 45,
  }) async {
    final scheduleTime = sahurTime.subtract(Duration(minutes: minutesBefore));
    if (scheduleTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);
    // ignore: avoid_print
    print('Scheduling sahur notification for: $sahurTime (alert at $tzTime)');
    try {
      await _plugin.zonedSchedule(
        id: _sahurId,
        title: 'VAKT',
        body: 'Sahura $minutesBefore dakika kaldı. Uyanma vakti.',
        scheduledDate: tzTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'vakt_sahur',
            'Sahur Bildirimi',
            channelDescription: 'Sahur vakti hatırlatması',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory
                .alarm, // Important for battery overrides
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      // ignore: avoid_print
      print('Sahur notification scheduled successfully');
    } catch (e) {
      // ignore: avoid_print
      print('NOTIFICATION ERROR (sahur): $e');
    }
  }

  static Future<void> scheduleDailyNotifications(double lat, double lng) async {
    // ignore: avoid_print
    print('=== SCHEDULING NOTIFICATIONS ===');
    // ignore: avoid_print
    print('Current time: ${DateTime.now()}');

    await cancelAll();

    final storage = StorageService();
    final prayerService = PrayerTimeService();
    final now = DateTime.now();
    final times = prayerService.getDailyPrayerTimes(lat, lng, now);

    final notifyIftar = storage.getSetting<bool>('notify_iftar') ?? true;
    final notifySahur = storage.getSetting<bool>('notify_sahur') ?? true;

    // ignore: avoid_print
    print('Iftar enabled: $notifyIftar | Sahur enabled: $notifySahur');

    if (notifyIftar) {
      var maghrib = times['maghrib'];
      if (maghrib != null && maghrib.isBefore(now)) {
        maghrib = prayerService.getDailyPrayerTimes(
          lat,
          lng,
          now.add(const Duration(days: 1)),
        )['maghrib'];
      }
      if (maghrib != null) {
        await scheduleIftarNotification(maghrib);
      }
    }

    if (notifySahur) {
      var fajr = times['fajr'];
      if (fajr != null && fajr.isBefore(now)) {
        fajr = prayerService.getDailyPrayerTimes(
          lat,
          lng,
          now.add(const Duration(days: 1)),
        )['fajr'];
      }
      if (fajr != null) {
        await scheduleSahurNotification(fajr);
      }
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
