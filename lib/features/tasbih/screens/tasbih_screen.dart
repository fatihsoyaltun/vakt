import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/storage_service.dart';

class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> {
  final _storage = StorageService();

  int _count = 0;
  int _loop = 0;
  int _target = 33;
  int _lifetimeCount = 0;

  @override
  void initState() {
    super.initState();
    _count = _storage.getSetting<int>('tasbih_count') ?? 0;
    _loop = _storage.getSetting<int>('tasbih_loop') ?? 0;
    _target = _storage.getSetting<int>('tasbih_target') ?? 33;
    _lifetimeCount = _storage.getSetting<int>('tasbih_lifetime_count') ?? 0;
  }

  void _triggerMilestoneHaptic() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
  }

  void _increment() {
    setState(() {
      if (_count >= _target) {
        _count = 0;
        _loop++;
      }
      
      _count++;
      _lifetimeCount++;

      if (_count == 33 || _count == 66 || _count == 99 || (_count % 100 == 0)) {
        _triggerMilestoneHaptic();
      } else {
        HapticFeedback.lightImpact();
      }
    });
    _persist();
  }

  void _reset() {
    HapticFeedback.vibrate();
    setState(() {
      _count = 0;
      _loop = 0;
    });
    _persist();
  }

  void _setTarget(int target) {
    HapticFeedback.selectionClick();
    setState(() {
      _target = target;
      _count = 0;
      _loop = 0;
    });
    _persist();
  }

  void _persist() {
    _storage.saveSetting('tasbih_count', _count);
    _storage.saveSetting('tasbih_loop', _loop);
    _storage.saveSetting('tasbih_target', _target);
    _storage.saveSetting('tasbih_lifetime_count', _lifetimeCount);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _target > 0 ? (_count / _target).clamp(0.0, 1.0) : 0.0;
    final isComplete = _count == _target;

    return SafeArea(
      child: Column(
        children: [
          // TOP BAR: target chips + reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _TargetChip(
                  label: '33',
                  selected: _target == 33,
                  onTap: () => _setTarget(33),
                ),
                const SizedBox(width: 8),
                _TargetChip(
                  label: '99',
                  selected: _target == 99,
                  onTap: () => _setTarget(99),
                ),
                const SizedBox(width: 8),
                _TargetChip(
                  label: '∞',
                  selected: _target >= 999999,
                  onTap: () => _setTarget(999999),
                ),
                const Spacer(),
                Tooltip(
                  message: "Sıfırlamak için basılı tutun",
                  child: InkWell(
                    onLongPress: _reset,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Sıfırla',
                            style: AppTextStyles.captionOf(context).copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MAIN COUNTER AREA
          Expanded(
            child: GestureDetector(
              onTap: _increment,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress ring + count
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              builder: (context, value, _) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 4,
                                  backgroundColor: AppColors.card(context),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isComplete ? AppColors.gold : AppColors.emerald,
                                  ),
                                );
                              },
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_count',
                                style: const TextStyle(
                                  fontFamily: 'Poppins', 
                                  fontSize: 80,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -2,
                                ),
                              ),
                              if (_target < 999999)
                                Text(
                                  '/ $_target',
                                  style: AppTextStyles.bodyOf(context).copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 18,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Loop counter
                    if (_loop > 0) ...[
                      Text(
                        'Tur: $_loop',
                        style: AppTextStyles.titleOf(context).copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Toplam: $_lifetimeCount',
                      style: AppTextStyles.captionOf(context).copyWith(
                        color: AppColors.textSecondary.withAlpha((0.6 * 255).round()),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Tap hint
                    Text(
                      'Saymak için ekrana dokun',
                      style: AppTextStyles.captionOf(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TargetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald.withAlpha((0.15 * 255).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.card(context),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyOf(context).copyWith(
            color: selected ? AppColors.emerald : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
