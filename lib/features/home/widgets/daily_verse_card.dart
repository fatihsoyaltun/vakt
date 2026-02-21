import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/home_provider.dart';

class DailyVerseCard extends ConsumerStatefulWidget {
  const DailyVerseCard({super.key});

  @override
  ConsumerState<DailyVerseCard> createState() => _DailyVerseCardState();
}

class _DailyVerseCardState extends ConsumerState<DailyVerseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final verseAsync = ref.watch(verseProvider);

    return verseAsync.when(
      loading: () => Card(
        color: AppColors.card(context),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (verse) => GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Card(
          color: AppColors.card(context),
          clipBehavior: Clip.hardEdge,
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
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Günün Ayeti',
                              style: AppTextStyles.titleOf(context)
                                  .copyWith(color: AppColors.gold),
                            ),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedCrossFade(
                            firstChild: Text(
                              verse.arabic,
                              style: GoogleFonts.amiriQuran(
                                fontSize: 16,
                                color: AppColors.text(context),
                                height: 1.8,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              verse.arabic,
                              style: GoogleFonts.amiriQuran(
                                fontSize: 18,
                                color: AppColors.text(context),
                                height: 1.8,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                            crossFadeState: _expanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedCrossFade(
                          firstChild: Text(
                            verse.turkish,
                            style: AppTextStyles.bodyOf(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            verse.turkish,
                            style: AppTextStyles.bodyOf(context),
                          ),
                          crossFadeState: _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${verse.surahTr} Suresi, Ayet ${verse.ayah} • ${verse.source}',
                          style: AppTextStyles.captionOf(context)
                              .copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
