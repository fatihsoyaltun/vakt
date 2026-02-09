import 'package:adhan/adhan.dart';

class PrayerTimeService {
  static final _params = CalculationMethod.turkey.getParameters();

  PrayerTimes getPrayerTimesForDate(
      double latitude, double longitude, DateTime date) {
    final coordinates = Coordinates(latitude, longitude);
    final dateComponents = DateComponents.from(date);
    return PrayerTimes(coordinates, dateComponents, _params);
  }

  Map<String, DateTime> getDailyPrayerTimes(
      double lat, double lng, DateTime date) {
    final pt = getPrayerTimesForDate(lat, lng, date);
    return {
      'fajr': pt.fajr,
      'sunrise': pt.sunrise,
      'dhuhr': pt.dhuhr,
      'asr': pt.asr,
      'maghrib': pt.maghrib,
      'isha': pt.isha,
    };
  }

  Duration getTimeUntilIftar(double lat, double lng) {
    final now = DateTime.now();
    final pt = getPrayerTimesForDate(lat, lng, now);
    final diff = pt.maghrib.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration getTimeUntilSahur(double lat, double lng) {
    final now = DateTime.now();
    final todayPt = getPrayerTimesForDate(lat, lng, now);

    // If fajr hasn't passed yet today, sahur is today's fajr
    if (now.isBefore(todayPt.fajr)) {
      return todayPt.fajr.difference(now);
    }

    // Otherwise, sahur is tomorrow's fajr
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowPt = getPrayerTimesForDate(lat, lng, tomorrow);
    final diff = tomorrowPt.fajr.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  String getNextPrayer(double lat, double lng) {
    final now = DateTime.now();
    final pt = getPrayerTimesForDate(lat, lng, now);
    final next = pt.nextPrayer();

    switch (next) {
      case Prayer.fajr:
        return 'İmsak';
      case Prayer.sunrise:
        return 'Güneş';
      case Prayer.dhuhr:
        return 'Öğle';
      case Prayer.asr:
        return 'İkindi';
      case Prayer.maghrib:
        return 'Akşam';
      case Prayer.isha:
        return 'Yatsı';
      case Prayer.none:
        // All prayers passed today, next is tomorrow's fajr
        return 'İmsak';
    }
  }
}
