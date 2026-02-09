import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/prayer_times_card.dart';
import '../widgets/daily_verse_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _buildDateString() {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';

    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    final miladiStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return '$hijriStr  •  $miladiStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            if (location.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Text(location.cityName, style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(_buildDateString(), style: AppTextStyles.caption),

            const SizedBox(height: 24),

            // COUNTDOWN
            const CountdownWidget(),

            const SizedBox(height: 24),

            // PRAYER TIMES
            const PrayerTimesCard(),

            const SizedBox(height: 24),

            // DAILY VERSE
            const DailyVerseCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
