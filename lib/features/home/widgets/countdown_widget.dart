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
          // Primary layer: Iftar countdown
          Text(
            'İftara Kalan',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white.withAlpha(200),
            ),
          ),
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

          const SizedBox(height: 24),

          // Secondary layer: Sahur & Next Prayer row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Sahur Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Sahura Kalan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 4),
                    sahurAsync.when(
                      data: (duration) {
                        final passed = duration <= Duration.zero;
                        return Text(
                          _formatDuration(passed ? Duration.zero : duration),
                          style: AppTextStyles.body.copyWith(
                            color: passed
                                ? AppColors.white.withAlpha(90)
                                : AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      loading: () => Text(
                        '--:--:--',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, _) => Text(
                        '--:--:--',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Divider
                Container(
                  height: 32,
                  width: 1,
                  color: AppColors.white.withAlpha(50),
                ),

                // Next Prayer Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Sıradaki Vakit',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (!prayerState.isLoading &&
                              prayerState.nextPrayer.isNotEmpty)
                          ? prayerState.nextPrayer
                          : '--',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
