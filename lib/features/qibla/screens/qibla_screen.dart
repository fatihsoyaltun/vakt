import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
// ignore: implementation_imports
import 'package:flutter_qiblah/src/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/home_provider.dart';


class QiblaScreen extends ConsumerStatefulWidget {
  final bool isActive;

  const QiblaScreen({super.key, this.isActive = true});

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
          final rawHeading = event.heading;
          if (mounted && rawHeading != null) {
            final h = (rawHeading + 360) % 360; // Always 0-360
            if (_heading == null) {
              setState(() => _heading = h);
            } else {
              double diff = h - _heading!;
              if (diff > 180) diff -= 360;
              if (diff < -180) diff += 360;
              double smoothed = (_heading! + diff * 0.15); // Sakin EMA smoothing 
              smoothed = (smoothed + 360) % 360;
              setState(() => _heading = smoothed);
            }
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
  void didUpdateWidget(covariant QiblaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      // Becoming inactive — pause compass stream and stop animations.
      _compassSub?.pause();
      _pulseController.stop();
      _pulseController.value = 1.0;
      _hapticFired = false;
    } else if (!oldWidget.isActive && widget.isActive) {
      // Becoming active — resume compass stream.
      if (_compassSub != null && _compassSub!.isPaused) {
        _compassSub!.resume();
      } else if (_compassSub == null && !_compassFailed) {
        _initCompass();
      }
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Signed difference in degrees (-180..180).
  /// Positive = qibla is clockwise from current heading.
  double _qiblaDiff(double heading, double qiblaAngle) {
    var diff = qiblaAngle - heading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  void _handleAlignment(bool isAligned) {
    if (!widget.isActive) return;
    if (isAligned && !_hapticFired) {
      HapticFeedback.lightImpact();
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
    final qiblaAngle = Utils.getOffsetFromNorth(location.lat, location.lng);

    // Still waiting for compass data and timeout hasn't fired yet.
    if (_heading == null && !_compassFailed) {
      return SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text('Kıble Yönü',
                  style: AppTextStyles.headlineOf(context),
                  textAlign: TextAlign.center),
              const Spacer(),
              const CircularProgressIndicator(color: AppColors.emerald),
              const SizedBox(height: 16),
              Text('Pusula başlatılıyor…',
                  style: AppTextStyles.captionOf(context),
                  textAlign: TextAlign.center),
              const Spacer(),
            ],
          ),
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

    // ignore: avoid_print
    print('Device heading: $heading | Qibla: $qiblaAngle | Diff: $diff');

    if (isLive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAlignment(isAligned);
      });
    }

    final arrowColor = isAligned ? const Color(0xFF4CD964) : AppColors.gold;

    return SizedBox(
      width: double.infinity,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text('Kıble Yönü',
            style: AppTextStyles.headlineOf(context),
            textAlign: TextAlign.center),
        const Spacer(),

        // ── Compass ──
        Center(
          child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating compass face
              Transform.rotate(
                angle: -heading * (math.pi / 180),
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: _CompassPainter(
                    cardinalColor: AppColors.text(context),
                    tickColor: AppColors.textSecondary,
                  ),
                ),
              ),

              // Qibla indicator (mosque + arrow)
              Transform.rotate(
                angle: (qiblaAngle - heading) * (math.pi / 180),
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
        ),

        const SizedBox(height: 28),

        // ── Alignment feedback ──
        if (isAligned)
          Text(
            'Kıble Yönündesiniz ✓',
            style: AppTextStyles.titleOf(context).copyWith(
                  color: const Color(0xFF4CD964),
                ),
            textAlign: TextAlign.center,
          )
        else
          Text(
            diff > 0
                ? '${diff.abs().round()}° sağa dönün →'
                : '← ${diff.abs().round()}° sola dönün',
            style: AppTextStyles.bodyOf(context),
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 24),

        // ── Info section ──
        Text(
          '${qiblaAngle.toStringAsFixed(1)}°',
          style: AppTextStyles.titleOf(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _cardinalDirection(qiblaAngle),
          style: AppTextStyles.captionOf(context),
          textAlign: TextAlign.center,
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
    ),
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

    // ── Tick marks (only large ones every 30° to reduce visual noise) ──
    final tickPaint = Paint();
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * (math.pi / 180);
      final isCardinal = i % 3 == 0; // 0°, 90°, 180°, 270°

      final tickOuter = outerR - 4;
      double tickInner;

      if (isCardinal) {
        tickInner = outerR - 24;
        tickPaint
          ..color = cardinalColor.withAlpha(200)
          ..strokeWidth = 2.0;
      } else {
        tickInner = outerR - 14;
        tickPaint
          ..color = tickColor.withAlpha(120)
          ..strokeWidth = 1.5;
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
