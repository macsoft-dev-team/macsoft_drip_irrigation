import 'dart:math';
import 'package:flutter/material.dart';

class TankLevelIndicator extends StatefulWidget {
  final double level; // 0.0 to 100.0

  const TankLevelIndicator({super.key, required this.level});

  @override
  State<TankLevelIndicator> createState() => _TankLevelIndicatorState();
}

class _TankLevelIndicatorState extends State<TankLevelIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _baseColor {
    if (widget.level < 20) return const Color(0xFFEF4444); // Red
    if (widget.level < 50) return const Color(0xFFF59E0B); // Orange/Amber
    return const Color(0xFF2563EB); // Royal Blue
  }

  String get _statusText {
    if (widget.level < 20) return 'LOW';
    if (widget.level < 50) return 'MODERATE';
    return 'OPTIMAL';
  }

  String get _description {
    if (widget.level < 20) {
      return 'Water level is critically low. Start pump motor soon.';
    }
    if (widget.level < 50) {
      return 'Water level is moderate. Adequate for short sequences.';
    }
    return 'Water storage is high. Ready for complete irrigation run.';
  }

  @override
  Widget build(BuildContext context) {
    final levelPct = widget.level.clamp(0.0, 100.0) / 100.0;
    final primaryColor = _baseColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // The Premium Wave Animated Tank Capsule
          Stack(
            alignment: Alignment.center,
            children: [
              // Glass Tank Outline & Content
              Container(
                width: 80,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Double Overlapping Animated Waves
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(80, 140),
                            painter: DoubleWavePainter(
                              progress: levelPct,
                              phase: _animationController.value * 2 * pi,
                              waveColor: primaryColor,
                            ),
                          );
                        },
                      ),
                      // Technical Scale / Ticks Overlay
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: _TankScaleOverlay(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating Badge in middle of tank (optional, can omit to keep it clean)
            ],
          ),
          const SizedBox(width: 24),
          // Information Panel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TANK STORAGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8A958A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.level.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 13,
                      color: const Color(0xFF64748B).withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live updates via telemetry',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DoubleWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double phase; // 0.0 to 2 * pi
  final Color waveColor;

  DoubleWavePainter({
    required this.progress,
    required this.phase,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final fillHeight = size.height * progress;
    final waterY = size.height - fillHeight;

    // 1. Draw Background Wave (semi-transparent, shifted phase, slightly different speed/amplitude)
    final bgPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final bgPath = Path();
    bgPath.moveTo(0, waterY);

    const bgWaveHeight = 5.0;
    final bgWaveLength = size.width * 1.2;

    for (double x = 0; x <= size.width; x++) {
      final y = waterY +
          sin((x / bgWaveLength) * 2 * pi - phase + (pi / 2)) * bgWaveHeight;
      bgPath.lineTo(x, y);
    }
    bgPath.lineTo(size.width, size.height);
    bgPath.lineTo(0, size.height);
    bgPath.close();
    canvas.drawPath(bgPath, bgPaint);

    // 2. Draw Foreground Wave (opaque, regular phase)
    final fgPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final fgPath = Path();
    fgPath.moveTo(0, waterY);

    const fgWaveHeight = 4.5;
    final fgWaveLength = size.width;

    for (double x = 0; x <= size.width; x++) {
      final y = waterY +
          sin((x / fgWaveLength) * 2 * pi + phase) * fgWaveHeight;
      fgPath.lineTo(x, y);
    }
    fgPath.lineTo(size.width, size.height);
    fgPath.lineTo(0, size.height);
    fgPath.close();
    canvas.drawPath(fgPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant DoubleWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.waveColor != waveColor;
  }
}

class _TankScaleOverlay extends StatelessWidget {
  const _TankScaleOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        // Generate scale ticks at 100%, 75%, 50%, 25%, 0%
        final val = 100 - (index * 25);
        final isMajor = val % 50 == 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left tick line
              Container(
                width: isMajor ? 8 : 4,
                height: 1.5,
                color: const Color(0xFF94A3B8).withValues(alpha: 0.35),
              ),
              // Optional minor label in center of cylinder, let's keep it clean
              Text(
                '$val%',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: isMajor ? FontWeight.w900 : FontWeight.w500,
                  color: const Color(0xFF64748B).withValues(alpha: 0.25),
                ),
              ),
              // Right tick line
              Container(
                width: isMajor ? 8 : 4,
                height: 1.5,
                color: const Color(0xFF94A3B8).withValues(alpha: 0.35),
              ),
            ],
          ),
        );
      }),
    );
  }
}
