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

  @override
  void initState() {
    super.initState();
    _count = _storage.getSetting<int>('tasbih_count') ?? 0;
    _loop = _storage.getSetting<int>('tasbih_loop') ?? 0;
    _target = _storage.getSetting<int>('tasbih_target') ?? 33;
  }

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      if (_count >= _target) {
        _count = 0;
        _loop++;
      }
    });
    _persist();
  }

  void _reset() {
    setState(() {
      _count = 0;
      _loop = 0;
    });
    _persist();
  }

  void _setTarget(int target) {
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
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(ctx),
        title: Text('Sıfırla', style: AppTextStyles.titleOf(ctx)),
        content: Text(
          'Sayacı sıfırlamak istediğinize emin misiniz?',
          style: AppTextStyles.bodyOf(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Sıfırla', style: TextStyle(color: AppColors.emerald)),
          ),
        ],
      ),
    );
    if (confirmed == true) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _target > 0 ? _count / _target : 0.0;
    final isComplete = _count == 0 && _loop > 0;

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
                  selected: _target != 33 && _target != 99,
                  onTap: () => _setTarget(999999),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary),
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
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor:
                                  AppColors.card(context),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isComplete
                                    ? AppColors.gold
                                    : AppColors.emerald,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_count',
                                style: TextStyle(fontFamily: 'Poppins', 
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text(context),
                                ),
                              ),
                              if (_target < 999999)
                                Text(
                                  '/ $_target',
                                  style: AppTextStyles.captionOf(context),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Loop counter
                    Text(
                      'Tur: $_loop',
                      style: AppTextStyles.titleOf(context).copyWith(
                        color: _loop > 0
                            ? AppColors.gold
                            : AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Tap hint
                    Text(
                      'Saymak için dokun',
                      style: AppTextStyles.captionOf(context),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyOf(context).copyWith(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
