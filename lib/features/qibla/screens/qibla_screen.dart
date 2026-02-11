import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/home_provider.dart';

// Kaaba coordinates
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;

/// Calculate qibla bearing from [lat],[lng] to the Kaaba using the atan2 formula.
double _calculateQiblaBearing(double lat, double lng) {
  final phi1 = lat * (math.pi / 180);
  final phi2 = _kaabaLat * (math.pi / 180);
  final dLambda = (_kaabaLng - lng) * (math.pi / 180);

  final y = math.sin(dLambda);
  final x = math.cos(phi1) * math.tan(phi2) -
      math.sin(phi1) * math.cos(dLambda);

  final bearing = math.atan2(y, x) * (180 / math.pi);
  return (bearing + 360) % 360;
}

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  bool _compassFailed = false;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..value = 1.0;
    _initCompass();
  }

  Future<void> _initCompass() async {
    // Start a 3-second timeout; if no data arrives, fall back to static.
    final timeout = Timer(const Duration(seconds: 3), () {
      if (_heading == null && mounted) {
        setState(() => _compassFailed = true);
      }
    });

    try {
      _compassSub = FlutterCompass.events?.listen(
        (event) {
          timeout.cancel();
          if (mounted) {
            setState(() => _heading = event.heading);
          }
        },
        onError: (_) {
          timeout.cancel();
          if (mounted) setState(() => _compassFailed = true);
        },
      );

      // If FlutterCompass.events is null (no sensor), fail immediately.
      if (_compassSub == null) {
        timeout.cancel();
        if (mounted) setState(() => _compassFailed = true);
      }
    } catch (_) {
      timeout.cancel();
      if (mounted) setState(() => _compassFailed = true);
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Signed difference in degrees (-180..180).
  /// Positive = qibla is clockwise from heading.
  double _qiblaDiff(double heading, double qiblaAngle) {
    double diff = (qiblaAngle - heading) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  void _handleAlignment(bool isAligned) {
    if (isAligned && !_hapticFired) {
      HapticFeedback.heavyImpact();
      _hapticFired = true;
      _pulseController.repeat(reverse: true);
    } else if (!isAligned && _hapticFired) {
      _hapticFired = false;
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final qiblaAngle = _calculateQiblaBearing(location.lat, location.lng);

    // Still waiting for compass data and timeout hasn't fired yet.
    if (_heading == null && !_compassFailed) {
      return SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Kıble Yönü', style: AppTextStyles.headlineOf(context)),
            const Spacer(),
            const CircularProgressIndicator(color: AppColors.emerald),
            const SizedBox(height: 16),
            Text('Pusula başlatılıyor…',
                style: AppTextStyles.captionOf(context)),
            const Spacer(),
          ],
        ),
      );
    }

    final heading = _heading ?? 0.0;
    final isLive = !_compassFailed;

    return SafeArea(
      child: _buildContent(
        context: context,
        heading: heading,
        qiblaAngle: qiblaAngle,
        isLive: isLive,
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required double heading,
    required double qiblaAngle,
    required bool isLive,
  }) {
    final diff = _qiblaDiff(heading, qiblaAngle);
    final isAligned = diff.abs() <= 5;

    if (isLive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAlignment(isAligned);
      });
    }

    final arrowColor = isAligned ? const Color(0xFF4CD964) : AppColors.gold;

    return Column(
      children: [
        const SizedBox(height: 16),
        Text('Kıble Yönü', style: AppTextStyles.headlineOf(context)),
        const Spacer(),

        // ── Compass ──
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating compass face
              AnimatedRotation(
                turns: -heading / 360,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: _CompassPainter(
                    cardinalColor: AppColors.text(context),
                    tickColor: AppColors.textSecondary,
                  ),
                ),
              ),

              // Qibla indicator (mosque + arrow)
              AnimatedRotation(
                turns: (qiblaAngle - heading) / 360,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Transform.scale(
                    scale: isAligned ? _pulseController.value : 1.0,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                  child: _buildQiblaIndicator(arrowColor),
                ),
              ),

              // Center dot
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Alignment feedback ──
        if (isAligned)
          Text(
            'Kıble Yönündesiniz ✓',
            style: AppTextStyles.titleOf(context).copyWith(
                  color: const Color(0xFF4CD964),
                ),
          )
        else
          Text(
            diff > 0
                ? '${diff.abs().round()}° sağa dönün →'
                : '← ${diff.abs().round()}° sola dönün',
            style: AppTextStyles.bodyOf(context),
          ),

        const SizedBox(height: 24),

        // ── Info section ──
        Text(
          '${qiblaAngle.toStringAsFixed(1)}°',
          style: AppTextStyles.titleOf(context),
        ),
        const SizedBox(height: 4),
        Text(
          _cardinalDirection(qiblaAngle),
          style: AppTextStyles.captionOf(context),
        ),

        const Spacer(),

        // ── Hint ──
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            isLive
                ? 'Cihazınızı düz tutun'
                : 'Pusula verisi alınamadı — statik yön gösteriliyor',
            style: AppTextStyles.captionOf(context),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
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

  Widget _buildQiblaIndicator(Color color) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.mosque_rounded, color: color, size: 28),
          const SizedBox(height: 2),
          Container(
            width: 3,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withAlpha(0)],
              ),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compass painter – gradient ring, tick marks, cardinal labels (K/G/D/B)
// ---------------------------------------------------------------------------

class _CompassPainter extends CustomPainter {
  final Color cardinalColor;
  final Color tickColor;

  _CompassPainter({required this.cardinalColor, required this.tickColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outerR = radius - 8;

    // ── Gradient outer ring ──
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.emerald.withAlpha(80),
          AppColors.emerald,
          AppColors.emerald.withAlpha(80),
          AppColors.emerald,
          AppColors.emerald.withAlpha(80),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, outerR, ringPaint);

    // ── Tick marks (every 5°; large every 30°) ──
    final tickPaint = Paint();
    for (int i = 0; i < 72; i++) {
      final angle = i * 5 * (math.pi / 180);
      final isCardinal = i % 18 == 0; // 0°, 90°, 180°, 270°
      final isLarge = i % 6 == 0; // every 30°

      final tickOuter = outerR - 2;
      double tickInner;

      if (isCardinal) {
        tickInner = outerR - 28;
        tickPaint
          ..color = cardinalColor
          ..strokeWidth = 2.5;
      } else if (isLarge) {
        tickInner = outerR - 20;
        tickPaint
          ..color = tickColor
          ..strokeWidth = 1.5;
      } else {
        tickInner = outerR - 12;
        tickPaint
          ..color = tickColor.withAlpha(80)
          ..strokeWidth = 1;
      }

      canvas.drawLine(
        Offset(
          center.dx + tickInner * math.sin(angle),
          center.dy - tickInner * math.cos(angle),
        ),
        Offset(
          center.dx + tickOuter * math.sin(angle),
          center.dy - tickOuter * math.cos(angle),
        ),
        tickPaint,
      );
    }

    // ── Cardinal labels (K=North red, D=East, G=South, B=West) ──
    const labels = ['K', 'D', 'G', 'B'];
    final colors = [
      const Color(0xFFE74C3C), // K – red
      cardinalColor,
      cardinalColor,
      cardinalColor,
    ];
    for (int i = 0; i < 4; i++) {
      final angle = i * 90 * (math.pi / 180);
      final labelR = outerR - 42;
      final pos = Offset(
        center.dx + labelR * math.sin(angle),
        center.dy - labelR * math.cos(angle),
      );
      final tp = TextPainter(
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
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.cardinalColor != cardinalColor || old.tickColor != tickColor;
}
