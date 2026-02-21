import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';

class CountdownWidget extends ConsumerWidget {
  const CountdownWidget({super.key});

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerTimesProvider);
    final iftarAsync = ref.watch(iftarCountdownProvider);
    final sahurAsync = ref.watch(sahurCountdownProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.darkBackground],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Iftar countdown (primary, large)
          Text('İftara Kalan', style: AppTextStyles.body),
          const SizedBox(height: 4),
          iftarAsync.when(
            data: (duration) {
              final passed = duration <= Duration.zero;
              return Text(
                _formatDuration(passed ? Duration.zero : duration),
                style: AppTextStyles.countdown.copyWith(
                  color: passed
                      ? AppColors.white.withAlpha(90)
                      : AppColors.white,
                ),
              );
            },
            loading: () => Text('--:--:--', style: AppTextStyles.countdown),
            error: (_, _) => Text('--:--:--', style: AppTextStyles.countdown),
          ),

          const SizedBox(height: 16),

          // Sahur countdown (secondary, smaller)
          Text(
            'Sahura Kalan',
            style: AppTextStyles.caption.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 2),
          sahurAsync.when(
            data: (duration) {
              final passed = duration <= Duration.zero;
              return Text(
                _formatDuration(passed ? Duration.zero : duration),
                style: AppTextStyles.countdown.copyWith(
                  fontSize: 32,
                  color: passed
                      ? AppColors.white.withAlpha(90)
                      : AppColors.white,
                ),
              );
            },
            loading: () => Text(
              '--:--:--',
              style: AppTextStyles.countdown.copyWith(fontSize: 32),
            ),
            error: (_, _) => Text(
              '--:--:--',
              style: AppTextStyles.countdown.copyWith(fontSize: 32),
            ),
          ),

          const SizedBox(height: 12),

          // Next prayer
          if (!prayerState.isLoading && prayerState.nextPrayer.isNotEmpty)
            Text(
              'Sıradaki: ${prayerState.nextPrayer}',
              style: AppTextStyles.caption.copyWith(color: AppColors.white),
            ),
        ],
      ),
    );
  }
}
