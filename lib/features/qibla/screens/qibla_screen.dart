import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with SingleTickerProviderStateMixin {
  bool? _sensorAvailable;
  bool _wasAligned = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _checkSensor();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSensor() async {
    final supported = await FlutterQiblah.androidDeviceSensorSupport();
    if (mounted) {
      setState(() => _sensorAvailable = supported ?? true);
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

  /// Signed difference in degrees (-180..180).
  /// Positive = qibla is clockwise from heading.
  double _qiblaDiff(double heading, double qiblaAngle) {
    double diff = (qiblaAngle - heading) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  void _onAlignmentChanged(bool isAligned) {
    if (isAligned && !_wasAligned) {
      HapticFeedback.heavyImpact();
      _pulseController.repeat(reverse: true);
    } else if (!isAligned && _wasAligned) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
    _wasAligned = isAligned;
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final qiblaAngle =
        Qibla(Coordinates(location.lat, location.lng)).direction;

    return SafeArea(
      child: _sensorAvailable == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            )
          : _sensorAvailable!
              ? _buildLive(context, qiblaAngle)
              : _buildContent(
                  context: context,
                  heading: 0,
                  qiblaAngle: qiblaAngle,
                  isLive: false,
                ),
    );
  }

  Widget _buildLive(BuildContext context, double qiblaAngle) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.emerald),
          );
        }
        return _buildContent(
          context: context,
          heading: snapshot.data!.direction,
          qiblaAngle: qiblaAngle,
          isLive: true,
        );
      },
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
        _onAlignmentChanged(isAligned);
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
            '${diff.abs().round()}° '
            '${diff > 0 ? 'sağa dönün' : 'sola dönün'}',
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
                : 'Pusula sensörü bulunamadı — statik yön gösteriliyor',
            style: AppTextStyles.captionOf(context),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
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
// Compass painter – gradient ring, tick marks, cardinal labels
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
