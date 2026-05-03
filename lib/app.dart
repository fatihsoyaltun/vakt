import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/home/providers/home_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/widgets/fasting_summary_panel.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/tasbih/screens/tasbih_screen.dart';
import 'features/qibla/screens/qibla_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

class VaktApp extends ConsumerStatefulWidget {
  const VaktApp({super.key});

  @override
  ConsumerState<VaktApp> createState() => _VaktAppState();
}

class _VaktAppState extends ConsumerState<VaktApp> {
  late bool _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _onboardingComplete =
        StorageService().getSetting<bool>('onboarding_complete') ?? false;
  }

  void _completeOnboarding() {
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isLargeFont = ref.watch(largeFontProvider);

    return MaterialApp(
      title: 'VAKT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: TextScaler.linear(isLargeFont ? 1.25 : 1.0),
          ),
          child: child!,
        );
      },
      home: _onboardingComplete
          ? const _MainShell()
          : OnboardingScreen(onComplete: _completeOnboarding),
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _currentIndex = 0;
  late StreamSubscription _notifSub;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationService.selectNotificationStream.stream.listen((payload) {
      if (payload == 'iftar_alert') {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // ensure we have context and provider ref to show the sheet
          FastingSummaryPanel.showLoggingSheet(context, ref);
        });
      }
    });
  }

  @override
  void dispose() {
    _notifSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const TasbihScreen(),
          QiblaScreen(isActive: _currentIndex == 2),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card(context),
        selectedItemColor: AppColors.emerald,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Vakit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app_rounded),
            label: 'Tesbih',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Kıble',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
