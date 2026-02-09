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

    // Determine if we should show iftar or sahur countdown
    final bool showIftar = iftarAsync.whenOrNull(data: (d) => d > Duration.zero) ?? true;
    final label = showIftar ? 'İftara Kalan' : 'Sahura Kalan';
    final countdownAsync = showIftar ? iftarAsync : sahurAsync;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
          Text(label, style: AppTextStyles.body),
          const SizedBox(height: 8),
          countdownAsync.when(
            data: (duration) => Text(
              _formatDuration(duration),
              style: AppTextStyles.countdown,
            ),
            loading: () => Text('--:--:--', style: AppTextStyles.countdown),
            error: (_, _) => Text('--:--:--', style: AppTextStyles.countdown),
          ),
          const SizedBox(height: 12),
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
