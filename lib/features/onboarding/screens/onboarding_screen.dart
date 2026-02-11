import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  void _nextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await StorageService().saveSetting('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _LocationPage(onNext: _nextPage),
                  _NotificationPage(onFinish: _finish),
                ],
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.emerald
                          : AppColors.textSecondary.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Page 1: Welcome ---

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.nightlight_round,
            color: AppColors.gold,
            size: 80,
          ),
          const SizedBox(height: 40),
          Text(
            'Her şeyin bir vakti var.',
            style: AppTextStyles.headline.copyWith(color: AppColors.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'VAKT',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.emerald,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Başla', style: AppTextStyles.title),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page 2: Location Permission ---

class _LocationPage extends StatelessWidget {
  final VoidCallback onNext;
  const _LocationPage({required this.onNext});

  Future<void> _requestLocation(BuildContext context) async {
    await LocationService().checkAndRequestPermission();
    onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.emerald,
            size: 60,
          ),
          const SizedBox(height: 32),
          Text(
            'Vaktini bilmek için\nkonumun gerek.',
            style: AppTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Namaz vakitlerini konumuna göre hesaplıyoruz.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _requestLocation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  Text('Konuma İzin Ver', style: AppTextStyles.title),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page 3: Notification Permission ---

class _NotificationPage extends StatelessWidget {
  final VoidCallback onFinish;
  const _NotificationPage({required this.onFinish});

  Future<void> _requestNotification() async {
    // ignore: avoid_print
    print('Notification permission button pressed');
    await NotificationService.init();
    onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_rounded,
            color: AppColors.emerald,
            size: 60,
          ),
          const SizedBox(height: 32),
          Text(
            'Hatırlatmamızı\nister misin?',
            style: AppTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'İftar ve sahur vakitlerinde seni bilgilendirelim.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _requestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Bildirimlere İzin Ver',
                  style: AppTextStyles.title),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onFinish,
            child: Text(
              'Şimdilik Geç',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
