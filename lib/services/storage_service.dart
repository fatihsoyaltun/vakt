import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const _settingsBox = 'settings';
  static const _prayerCacheBox = 'prayer_cache';

  static late Box _settings;
  static late Box _prayerCache;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settings = await Hive.openBox(_settingsBox);
    _prayerCache = await Hive.openBox(_prayerCacheBox);
  }

  Future<void> saveLastLocation(
      double lat, double lng, String cityName) async {
    await _settings.put('last_location', {
      'lat': lat,
      'lng': lng,
      'cityName': cityName,
    });
  }

  Map<String, dynamic>? getLastLocation() {
    final data = _settings.get('last_location');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  T? getSetting<T>(String key) {
    return _settings.get(key) as T?;
  }

  Future<void> savePrayerTimesCache(
      String dateKey, Map<String, String> times) async {
    await _prayerCache.put(dateKey, times);
  }

  Map<String, String>? getCachedPrayerTimes(String dateKey) {
    final data = _prayerCache.get(dateKey);
    if (data == null) return null;
    return Map<String, String>.from(data as Map);
  }
}
