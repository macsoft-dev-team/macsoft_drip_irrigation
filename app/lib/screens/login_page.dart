import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _introController;

  late Animation<double> _dropFall;
  late Animation<double> _dropStretch;
  late Animation<double> _rippleRadius;
  late Animation<double> _rippleOpacity;
  late Animation<double> _uiOpacity;
  late Animation<Offset> _uiSlide;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Droplet physics
    _dropFall = Tween<double>(begin: -150, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeInCubic),
      ),
    );
    _dropStretch = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    // Ripple physics
    _rippleRadius = Tween<double>(begin: 0, end: 600).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _rippleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
      ),
    );

    // UI Reveal
    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await context.read<AppState>().login(
      any: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!ok) {
      final err = context.read<AppState>().authError ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final impactY = size.height * 0.45; // Water hits right above the form

    return Scaffold(
      backgroundColor: const Color(
        0xFF9FB091,
      ), // Fallback color matching the image bottom
      body: Stack(
        children: [
          // ── 1. The Photographic Background ──
          Positioned.fill(
            child: Image.asset('assets/bg_leaves.png', fit: BoxFit.cover),
          ),

          // ── 2. Cinematic Ripple Effect (CRYSTAL CLEAR) ──
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              if (_introController.value < 0.30) return const SizedBox.shrink();
              return Positioned.fill(
                child: CustomPaint(
                  painter: RipplePainter(
                    radius: _rippleRadius.value,
                    opacity: _rippleOpacity.value,
                    center: Offset(size.width / 2, impactY),
                  ),
                ),
              );
            },
          ),

          // ── 3. Realistic Falling Droplet (CRYSTAL CLEAR) ──
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              if (_introController.value >= 0.30)
                return const SizedBox.shrink();
              return Positioned(
                top: impactY + _dropFall.value - 30,
                left: size.width / 2 - 8,
                child: CustomPaint(
                  size: const Size(16, 30),
                  painter: DropletPainter(stretch: _dropStretch.value),
                ),
              );
            },
          ),

          // ── 4. Progressive UI Reveal ──
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _uiOpacity,
                child: SlideTransition(position: _uiSlide, child: child),
              );
            },
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header is styled to pop against the darker top half of the image
                      Image.asset('assets/logo.png', width: 72, height: 72),
                      const SizedBox(height: 16),
                      const Text(
                        'Smart Drip',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors
                              .white, // White pops beautifully against the dark green leaves
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nurture every drop.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // The Form Card (Frosted glass sitting over the light olive fade)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.55,
                              ), // Translucent white
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E3B20,
                                  ).withOpacity(0.15), // Deep green shadow
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'System Login',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(
                                        0xFF1E3B20,
                                      ), // Dark Forest Green
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Access your irrigation dashboard',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4A634D), // Muted Olive
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  AppTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'you@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Email is required';
                                      if (!v.contains('@'))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  AppTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    obscureText: _obscurePassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: const Color(0xFF6B8E6E),
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password is required';
                                      if (v.length < 6)
                                        return 'Minimum 6 characters';
                                      return null;
                                    },
                                  ),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  SizedBox(
                                    width: double.infinity,
                                    child: PrimaryButton(
                                      label: 'Initialize',
                                      onPressed: _login,
                                      isLoading: _isLoading,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "System offline?",
                            style: TextStyle(
                              color: Color(0xFF4A634D),
                            ), // Muted olive
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1E3B20),
                            ), // Dark green
                            child: const Text(
                              'Contact Admin',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Realistic Droplet Painter (Tuned for Green Refraction) ──
class DropletPainter extends CustomPainter {
  final double stretch;

  DropletPainter({required this.stretch});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height * stretch;

    // Main Body
    final path = Path();
    path.moveTo(width / 2, 0);
    path.cubicTo(
      width * 0.8,
      height * 0.4,
      width,
      height * 0.7,
      width / 2,
      height,
    );
    path.cubicTo(0, height * 0.7, width * 0.2, height * 0.4, width / 2, 0);

    // Refracts white and a hint of the green leaf background
    final gradient = RadialGradient(
      center: const Alignment(-0.2, 0.3),
      radius: 0.8,
      colors: [
        Colors.white,
        const Color(
          0xFFE8F5E9,
        ).withOpacity(0.9), // Very light translucent green
        const Color(0xFF81C784).withOpacity(0.5), // Soft leaf green shadow
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill,
    );

    // Specular Highlight (The crisp white reflection that makes it look like real water)
    final highlight = Path();
    highlight.addOval(
      Rect.fromLTWH(width * 0.2, height * 0.15, width * 0.35, height * 0.25),
    );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant DropletPainter oldDelegate) =>
      oldDelegate.stretch != stretch;
}

// ── Energy Dissipation Ripple Painter (Crisp Vectors) ──
class RipplePainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Offset center;

  RipplePainter({
    required this.radius,
    required this.opacity,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius == 0 || opacity == 0) return;

    for (int i = 0; i < 3; i++) {
      final currentRadius = (radius - (i * 45)).clamp(0.0, double.infinity);
      if (currentRadius <= 0) continue;

      final currentOpacity = (opacity - (i * 0.25)).clamp(0.0, 1.0);

      // Crisp, thin strokes imitating physical water tension on the leaves
      final currentStroke = (3.0 - (radius / 250) - (i * 0.5)).clamp(0.5, 3.0);

      final paint = Paint()
        // White/clear strokes to act as reflections against the green photo
        ..color = Colors.white.withOpacity(currentOpacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke;

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.opacity != opacity;
}
