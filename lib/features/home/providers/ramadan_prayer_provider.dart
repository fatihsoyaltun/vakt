import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ramadan_prayer_model.dart';
import '../../../services/ramadan_prayer_service.dart';
import 'fasting_provider.dart';

final ramadanPrayerProvider = FutureProvider<RamadanPrayer>((ref) async {
  final service = RamadanPrayerService();
  final prayers = await service.loadPrayers();
  final fastingState = ref.watch(fastingProvider);
  final fastedDays = fastingState.summary.fasted;
  
  // Return the prayer corresponding to the total fasted days (e.g., 5th fasted day -> 5th prayer)
  return service.getPrayerForFastingDay(fastedDays, prayers);
});
