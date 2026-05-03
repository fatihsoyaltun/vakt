import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/fasting_provider.dart';

import '../widgets/daily_prayer_card.dart';

class FastingSummaryPanel extends ConsumerWidget {
  const FastingSummaryPanel({super.key});

  void _showLoggingSheet(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.read(fastingProvider.notifier).getTodayStatus();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bugün oruç tuttun mu?',
                  style: AppTextStyles.titleOf(context),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: currentStatus == 1
                        ? AppColors.emerald
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    'Niyetliyim / Tuttum',
                    style: AppTextStyles.bodyOf(context),
                  ),
                  onTap: () async {
                    await ref.read(fastingProvider.notifier).setStatusForToday(1);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      
                      // Sakin UI animation to show the daily prayer
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'DailyPrayerDismiss',
                        barrierColor: Colors.black.withAlpha(150),
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (bCtx, anim, secondaryAnim) => 
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                            ),
                            child: FadeTransition(opacity: anim, child: const DailyPrayerCard()),
                          ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.history,
                    color: currentStatus == 2
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    'Kaza / Tutamadım',
                    style: AppTextStyles.bodyOf(context),
                  ),
                  onTap: () {
                    ref.read(fastingProvider.notifier).setStatusForToday(2);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.close,
                    color: currentStatus == 0
                        ? Colors.redAccent
                        : AppColors.textSecondary,
                  ),
                  title: Text('Temizle', style: AppTextStyles.bodyOf(context)),
                  onTap: () {
                    ref.read(fastingProvider.notifier).setStatusForToday(0);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fastingProvider);
    final summary = state.summary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showLoggingSheet(context, ref);
      },
      child: Card(
        color: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oruç Takibi',
                    style: AppTextStyles.titleOf(
                      context,
                    ).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bugünü işaretlemek için dokun',
                    style: AppTextStyles.captionOf(context),
                  ),
                ],
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _RingsPainter(
                    fasted: summary.fasted,
                    debt: summary.debt,
                    remaining: summary.remaining,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final int fasted;
  final int debt;
  final int remaining;
  final int total = 30;

  _RingsPainter({
    required this.fasted,
    required this.debt,
    required this.remaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 2;
    const strokeWidth = 5.0;

    final basePaint = Paint()
      ..color = AppColors.darkBackground
          .withAlpha(20) // works for both light/dark subtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fastedPaint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final debtPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw base ring
    canvas.drawCircle(center, radius, basePaint);

    final startAngle = -pi / 2; // start from top
    double currentAngle = startAngle;

    // Draw fasted
    if (fasted > 0) {
      final sweepAngle = (fasted / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        fastedPaint,
      );
      currentAngle += sweepAngle;
    }

    // Draw debt
    if (debt > 0) {
      final sweepAngle = (debt / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        debtPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.fasted != fasted ||
        oldDelegate.debt != debt ||
        oldDelegate.remaining != remaining;
  }
}
