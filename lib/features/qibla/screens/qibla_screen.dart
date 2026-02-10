import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/home_provider.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  bool? _sensorAvailable;

  @override
  void initState() {
    super.initState();
    _checkSensor();
  }

  Future<void> _checkSensor() async {
    final supported = await FlutterQiblah.androidDeviceSensorSupport();
    if (mounted) {
      setState(() => _sensorAvailable = supported ?? false);
    }
  }

  String _cardinalDirection(double degree) {
    final d = degree % 360;
    if (d >= 337.5 || d < 22.5) return 'Kuzey';
    if (d < 67.5) return 'Kuzeydoğu';
    if (d < 112.5) return 'Doğu';
    if (d < 157.5) return 'Güneydoğu';
    if (d < 202.5) return 'Güney';
    if (d < 247.5) return 'Güneybatı';
    if (d < 292.5) return 'Batı';
    return 'Kuzeybatı';
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final qiblaAngle =
        Qibla(Coordinates(location.lat, location.lng)).direction;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('Kıble Yönü', style: AppTextStyles.headlineOf(context)),
          const SizedBox(height: 8),
          Text(
            '${qiblaAngle.toStringAsFixed(1)}° ${_cardinalDirection(qiblaAngle)}',
            style: AppTextStyles.captionOf(context),
          ),
          const SizedBox(height: 8),
          // Main compass area
          Expanded(
            child: _sensorAvailable == null
                ? const Center(child: CircularProgressIndicator())
                : _sensorAvailable == true
                    ? _LiveCompass(qiblaAngle: qiblaAngle)
                    : _StaticCompass(qiblaAngle: qiblaAngle),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              _sensorAvailable == true
                  ? 'Cihazınızı düz tutun'
                  : 'Pusula sensörü bulunamadı — statik yön gösteriliyor',
              style: AppTextStyles.captionOf(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Live compass with device sensor ---

class _LiveCompass extends StatelessWidget {
  final double qiblaAngle;
  const _LiveCompass({required this.qiblaAngle});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return _CompassView(
          compassAngle: data.direction,
          qiblaAngle: qiblaAngle,
        );
      },
    );
  }
}

// --- Static fallback (no sensor) ---

class _StaticCompass extends StatelessWidget {
  final double qiblaAngle;
  const _StaticCompass({required this.qiblaAngle});

  @override
  Widget build(BuildContext context) {
    return _CompassView(
      compassAngle: 0,
      qiblaAngle: qiblaAngle,
    );
  }
}

// --- Shared compass visual ---

class _CompassView extends StatelessWidget {
  final double compassAngle;
  final double qiblaAngle;

  const _CompassView({
    required this.compassAngle,
    required this.qiblaAngle,
  });

  @override
  Widget build(BuildContext context) {
    final compassRad = -compassAngle * (math.pi / 180);
    final qiblaRad = (qiblaAngle - compassAngle) * (math.pi / 180);

    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Compass circle + cardinal markers (rotates with compass)
            AnimatedRotation(
              turns: compassRad / (2 * math.pi),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: _CompassPainter(
                  ringColor: AppColors.card(context),
                  cardinalColor: AppColors.text(context),
                ),
              ),
            ),
            // Qibla arrow (rotates to qibla direction)
            AnimatedRotation(
              turns: qiblaRad / (2 * math.pi),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mosque_rounded,
                    color: AppColors.gold,
                    size: 32,
                  ),
                  Container(
                    width: 4,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.gold, AppColors.gold.withAlpha(0)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            // Center dot
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.emerald,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Color ringColor;
  final Color cardinalColor;

  _CompassPainter({required this.ringColor, required this.cardinalColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 8, ringPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.5;
    for (int i = 0; i < 72; i++) {
      final angle = i * 5 * (math.pi / 180);
      final isCardinal = i % 18 == 0;
      final isMajor = i % 9 == 0;
      final outerR = radius - 10;
      final innerR =
          isCardinal ? radius - 30 : (isMajor ? radius - 24 : radius - 18);

      if (isCardinal) {
        tickPaint.color = cardinalColor;
        tickPaint.strokeWidth = 2.5;
      } else if (isMajor) {
        tickPaint.color = AppColors.textSecondary;
        tickPaint.strokeWidth = 1.5;
      } else {
        tickPaint.color = AppColors.textSecondary.withAlpha(80);
        tickPaint.strokeWidth = 1;
      }

      final outerPoint = Offset(
        center.dx + outerR * math.sin(angle),
        center.dy - outerR * math.cos(angle),
      );
      final innerPoint = Offset(
        center.dx + innerR * math.sin(angle),
        center.dy - innerR * math.cos(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Cardinal labels
    const labels = ['K', 'D', 'G', 'B'];
    final colors = [
      const Color(0xFFE74C3C), // K = North, red
      cardinalColor,
      cardinalColor,
      cardinalColor,
    ];
    for (int i = 0; i < 4; i++) {
      final angle = i * 90 * (math.pi / 180);
      final labelR = radius - 44;
      final pos = Offset(
        center.dx + labelR * math.sin(angle),
        center.dy - labelR * math.cos(angle),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor ||
      oldDelegate.cardinalColor != cardinalColor;
}
