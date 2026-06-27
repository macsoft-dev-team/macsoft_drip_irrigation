import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a widget with chromatic aberration (red/cyan shift), screen shake,
/// and horizontal static slices when [active] is true.
class GlitchWidget extends StatefulWidget {
  final Widget child;
  final bool active;
  final double glitchIntensity; // 0.0 to 1.0

  const GlitchWidget({
    super.key,
    required this.child,
    required this.active,
    this.glitchIntensity = 0.5,
  });

  @override
  State<GlitchWidget> createState() => _GlitchWidgetState();
}

class _GlitchWidgetState extends State<GlitchWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GlitchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Only glitch on certain frames to make it look like organic static burst
        final bool shouldGlitch = _random.nextDouble() < 0.65;
        if (!shouldGlitch) return widget.child;

        final double intensity = widget.glitchIntensity;
        // Jitter displacements
        final double dx = (_random.nextDouble() - 0.5) * 14.0 * intensity;
        final double dy = (_random.nextDouble() - 0.5) * 6.0 * intensity;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Cyan shifted shadow layer
            Transform.translate(
              offset: Offset(-dx, -dy),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.cyanAccent],
                ).createShader(bounds),
                blendMode: BlendMode.srcATop,
                child: Opacity(
                  opacity: 0.45 * intensity,
                  child: widget.child,
                ),
              ),
            ),
            // Red shifted shadow layer
            Transform.translate(
              offset: Offset(dx, dy),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.redAccent, Colors.redAccent],
                ).createShader(bounds),
                blendMode: BlendMode.srcATop,
                child: Opacity(
                  opacity: 0.45 * intensity,
                  child: widget.child,
                ),
              ),
            ),
            // Main child layered in the middle with slight displacement
            Transform.translate(
              offset: Offset(dx * 0.2, dy * 0.2),
              child: widget.child,
            ),
            // Random horizontal colored lines (horizontal electrical glitches)
            Positioned.fill(
              child: CustomPaint(
                painter: GlitchOverlayPainter(
                  random: _random,
                  intensity: intensity,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints horizontal digital noise slices on top of the widget.
class GlitchOverlayPainter extends CustomPainter {
  final math.Random random;
  final double intensity;

  GlitchOverlayPainter({required this.random, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (random.nextDouble() > 0.4) return; // Only draw occasionally

    final paint = Paint()..style = PaintingStyle.fill;
    final int linesToDraw = random.nextInt(3) + 1;

    for (int i = 0; i < linesToDraw; i++) {
      final double width = size.width * (random.nextDouble() * 0.7 + 0.3);
      final double height = random.nextDouble() * 3.5 + 1.0;
      final double top = random.nextDouble() * size.height;
      final double left = random.nextDouble() * (size.width - width);

      // Random color: neon cyan, neon pink, neon green, or white
      final colors = [
        Colors.cyanAccent,
        const Color(0xFFFF007F), // Neon Pink
        const Color(0xFF39FF14), // Neon Green
        Colors.white,
      ];
      paint.color = colors[random.nextInt(colors.length)].withValues(alpha: 0.6);

      canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Decrypts/scrambles text characters continuously when [active] is true.
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool active;
  final TextAlign? textAlign;

  const GlitchText(
    this.text, {
    super.key,
    this.style,
    required this.active,
    this.textAlign,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  static const String _glitchChars = r"ØÆß§@#%&*0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ?#$![]{}<>";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _scrambleText(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      if (input[i] == ' ' || input[i] == '\n') {
        buffer.write(input[i]);
      } else if (_random.nextDouble() < 0.45) {
        // Scramble with a random character
        buffer.write(_glitchChars[_random.nextInt(_glitchChars.length)]);
      } else {
        buffer.write(input[i]);
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text(
          _scrambleText(widget.text),
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}

/// Overlays horizontal CRT scanlines and a radial screen vignette.
class CRTScanlines extends StatelessWidget {
  final Widget child;
  final bool active;

  const CRTScanlines({
    super.key,
    required this.child,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: CRTScanlinePainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class CRTScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw scanlines: horizontal parallel dark overlay lines
    const double lineSpacing = 3.5;
    for (double y = 0; y < size.height; y += lineSpacing) {
      paint.color = Colors.black.withValues(alpha: 0.12);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw CRT radial vignette
    final Rect rect = Offset.zero & size;
    final radialPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.40),
        ],
        stops: const [0.65, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, radialPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
