import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../home/providers/home_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _storage = StorageService();
  late bool _notifyIftar;
  late bool _notifySahur;

  @override
  void initState() {
    super.initState();
    _notifyIftar = _storage.getSetting<bool>('notify_iftar') ?? true;
    _notifySahur = _storage.getSetting<bool>('notify_sahur') ?? true;
  }

  void _rescheduleNotifications() {
    final location = ref.read(locationProvider);
    NotificationService.scheduleDailyNotifications(location.lat, location.lng);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final location = ref.watch(locationProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // APPEARANCE
          Text('Görünüm',
              style: AppTextStyles.titleOf(context).copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.card(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: Text('Karanlık Mod', style: AppTextStyles.bodyOf(context)),
              value: isDark,
              activeTrackColor: AppColors.emerald,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),

          const SizedBox(height: 24),

          // NOTIFICATIONS
          Text('Bildirimler',
              style: AppTextStyles.titleOf(context).copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.card(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('İftara 30 dakika kala',
                      style: AppTextStyles.bodyOf(context)),
                  value: _notifyIftar,
                  activeTrackColor: AppColors.emerald,
                  onChanged: (val) {
                    setState(() => _notifyIftar = val);
                    _storage.saveSetting('notify_iftar', val);
                    _rescheduleNotifications();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: Text('Sahura 45 dakika kala',
                      style: AppTextStyles.bodyOf(context)),
                  value: _notifySahur,
                  activeTrackColor: AppColors.emerald,
                  onChanged: (val) {
                    setState(() => _notifySahur = val);
                    _storage.saveSetting('notify_sahur', val);
                    _rescheduleNotifications();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // LOCATION
          Text('Konum',
              style: AppTextStyles.titleOf(context).copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.card(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.emerald),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.isLoading
                                  ? 'Yükleniyor...'
                                  : location.cityName,
                              style: AppTextStyles.bodyOf(context),
                            ),
                            Text(
                              '${location.lat.toStringAsFixed(4)}, ${location.lng.toStringAsFixed(4)}',
                              style: AppTextStyles.captionOf(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: location.isLoading
                          ? null
                          : () =>
                              ref.read(locationProvider.notifier).fetchLocation(),
                      icon: location.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: const Text('Konumu Güncelle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emerald,
                        side: const BorderSide(color: AppColors.emerald),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ABOUT
          Text('Hakkında',
              style: AppTextStyles.titleOf(context).copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.card(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _aboutRow(context, 'Uygulama', 'VAKT'),
                  const SizedBox(height: 8),
                  _aboutRow(context, 'Versiyon', 'v0.1.0'),
                  const SizedBox(height: 8),
                  _aboutRow(context, 'Geliştirici', 'Fatih Soyaltun & Ayça Dağdemir'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _aboutRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyOf(context)),
        Text(value, style: AppTextStyles.captionOf(context)),
      ],
    );
  }
}
