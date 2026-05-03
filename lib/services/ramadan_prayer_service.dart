import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/models/ramadan_prayer_model.dart';

class RamadanPrayerService {
  List<RamadanPrayer>? _cache;

  Future<List<RamadanPrayer>> loadPrayers() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/ramadan_prayers.json');
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      _cache = jsonList.map((e) => RamadanPrayer.fromJson(e as Map<String, dynamic>)).toList();
      return _cache!;
    } catch (e) {
      return [
        const RamadanPrayer(
          dayIndex: 1,
          title: "Günlük Dua",
          arabic: "اَللَّهُمَّ تَقَبَّلْ مِنَّا",
          turkish: "Allah'ım, bizden kabul eyle.",
        )
      ];
    }
  }

  RamadanPrayer getPrayerForRamadanDay(int ramadanDay, List<RamadanPrayer> prayers) {
    if (prayers.isEmpty) return const RamadanPrayer(dayIndex: 1, title: "", arabic: "", turkish: "");
    int index = ramadanDay > 0 ? ramadanDay - 1 : 0;
    index = index.clamp(0, prayers.length - 1);
    return prayers[index];
  }
}
