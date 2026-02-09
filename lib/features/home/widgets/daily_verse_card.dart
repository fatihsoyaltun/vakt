import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DailyVerseCard extends StatelessWidget {
  const DailyVerseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günün Ayeti',
              style: AppTextStyles.title.copyWith(color: AppColors.gold),
            ),
            const SizedBox(height: 8),
            Text(
              '"Şüphesiz her güçlükle bir kolaylık vardır."',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 4),
            Text(
              'İnşirah Suresi, 6',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
