import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ramadan_prayer_model.dart';
import '../../../services/prayer_time_service.dart';
import '../../../services/ramadan_prayer_service.dart';

final ramadanPrayerProvider = FutureProvider<RamadanPrayer>((ref) async {
  final service = RamadanPrayerService();
  final prayers = await service.loadPrayers();
  
  final prayerTimeService = PrayerTimeService();
  final ramadanDay = prayerTimeService.getCurrentRamadanDay();
  
  return service.getPrayerForRamadanDay(ramadanDay, prayers);
});
