import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';

class DailyVerseCard extends ConsumerWidget {
  const DailyVerseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verseAsync = ref.watch(verseProvider);

    return verseAsync.when(
      loading: () => const Card(
        color: AppColors.cardDark,
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (verse) => Card(
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günün Ayeti',
                        style: AppTextStyles.title
                            .copyWith(color: AppColors.gold),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          verse.arabic,
                          style: GoogleFonts.amiriQuran(
                            fontSize: 18,
                            color: AppColors.white,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        verse.turkish,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${verse.surahTr} Suresi, Ayet ${verse.ayah} • ${verse.source}',
                        style: AppTextStyles.caption,
                      ),
                    ],
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
