import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/ramadan_prayer_provider.dart';

class DailyPrayerCard extends ConsumerWidget {
  const DailyPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(ramadanPrayerProvider);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Allah kabul etsin.',
                style: AppTextStyles.titleOf(context).copyWith(color: AppColors.gold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              prayerAsync.when(
                data: (prayer) {
                  return Column(
                    children: [
                      Text(
                        prayer.title,
                        style: AppTextStyles.captionOf(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        prayer.arabic,
                        style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, height: 1.8),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        prayer.turkish,
                        style: AppTextStyles.bodyOf(context).copyWith(fontSize: 14, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('Dua yüklenemedi.'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat (Âmin)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
