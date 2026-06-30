import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_loading_button.dart';

enum AuthStep { splash, login, forgotPassword, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  AuthStep _currentStep = AuthStep.splash;
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController(text: "8888888888");
  final _passwordController = TextEditingController(text: "farmer12345");
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Animation Controllers & Animations
  late AnimationController _introController;
  late Animation<double> _dropFall;
  late Animation<double> _dropStretch;
  late Animation<double> _dropWobble;
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

    // Droplet physics (Ease in and accelerate downwards)
    _dropFall = Tween<double>(begin: -200, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeInCubic),
      ),
    );

    // Stretch physics (stretches dynamically, then squashes flat on impact)
    _dropStretch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 2.5).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 75,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.5, end: 0.6).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.30),
      ),
    );

    // Wobble and horizontal squash physics
    _dropWobble = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.75).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 1.5).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.30),
      ),
    );

    // Ripple physics (starts right on impact at 0.30)
    _rippleRadius = Tween<double>(begin: 0, end: 550).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _rippleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOut),
      ),
    );

    // UI Reveal (fades & slides up starting from 0.40)
    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
      ),
    );
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _introController.forward();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait until the droplet impacts (at 0.30 of the 3.5s animation = 1050ms)
    await Future.delayed(const Duration(milliseconds: 1050));
    if (!mounted) return;

    final state = context.read<AppState>();
    if (state.isAuthenticated) {
      // Authenticated user will auto-redirect in AppRootSelector, but update step for local UI safety
      setState(() => _currentStep = AuthStep.login);
    } else {
      setState(() => _currentStep = AuthStep.login);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AppState state) async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await state.login(any: phone, password: password);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully.'),
          backgroundColor: Color(0xFF2D7A3A),
        ),
      );
    } else {
      setState(() => _errorMessage = state.authError ?? 'Login failed. Please check your credentials.');
    }
  }

  Future<void> _handleSendOtp(AppState state) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await state.sendOtp(phone);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _currentStep = AuthStep.otp;
        _otpController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP code sent successfully. Try 123456.'),
          backgroundColor: Color(0xFF2D7A3A),
        ),
      );
    } else {
      setState(() => _errorMessage = 'Failed to send OTP. Try again.');
    }
  }

  Future<void> _handleVerifyOtp(AppState state) async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter a valid OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await state.verifyOtp(phone, otp);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identity verified. Logged in.'),
          backgroundColor: Color(0xFF2D7A3A),
        ),
      );
    } else {
      setState(() => _errorMessage = state.authError ?? 'OTP code verification failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final impactY = size.height * 0.40;

    final state = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF9FB091),
      body: Stack(
        children: [
          // ── 1. Photographic Background ──
          Positioned.fill(
            child: Image.asset(
              'assets/bg_leaves.png',
              fit: BoxFit.cover,
            ),
          ),

          // Subtle dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.18),
            ),
          ),

          // ── 2. Cinematic Elliptical Ripple Effect ──
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
                    animationValue: _introController.value,
                  ),
                ),
              );
            },
          ),

          // ── 3. Falling Droplet ──
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              if (_introController.value >= 0.30) return const SizedBox.shrink();

              final dropWidth = 16 * _dropWobble.value;
              final dropHeight = 30 * _dropStretch.value;

              return Positioned(
                top: impactY + _dropFall.value - dropHeight,
                left: size.width / 2 - (dropWidth / 2),
                child: CustomPaint(
                  size: Size(dropWidth, dropHeight),
                  painter: DropletPainter(
                    stretch: _dropStretch.value,
                    wobble: _dropWobble.value,
                  ),
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
                child: SlideTransition(
                  position: _uiSlide,
                  child: child,
                ),
              );
            },
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentStep != AuthStep.splash) ...[
                        // Sitting droplet logo container
                        CustomPaint(
                          size: const Size(80, 80),
                          painter: SittingDropletPainter(),
                          child: const SizedBox(
                            width: 80,
                            height: 80,
                            child: Center(
                              child: Icon(
                                Icons.water_drop_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DripFlow',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        const Text(
                          'Smart Drip Irrigation Platform',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8F5E9),
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                      _buildStepContent(state),
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

  Widget _buildStepContent(AppState state) {
    switch (_currentStep) {
      case AuthStep.splash:
        return const SizedBox.shrink();

      case AuthStep.login:
        return _buildGlassContainer(
          key: const ValueKey('loginInput'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Farmer!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E2A1F)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your credentials to manage and run valves.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Phone Number',
                hint: 'e.g. 8888888888',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF8A958A)),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'Enter password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF8A958A)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = AuthStep.forgotPassword;
                      _errorMessage = null;
                    });
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF2D7A3A), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppLoadingButton(
                label: 'Login',
                isLoading: _isLoading,
                onPressed: () => _handleLogin(state),
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        );

      case AuthStep.forgotPassword:
        return _buildGlassContainer(
          key: const ValueKey('forgotPasswordInput'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E2A1F)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter phone number. We will send you an OTP code to verify.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Phone Number',
                hint: 'e.g. 8888888888',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF8A958A)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
              AppLoadingButton(
                label: 'Send OTP',
                isLoading: _isLoading,
                onPressed: () => _handleSendOtp(state),
                color: const Color(0xFF2D7A3A),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = AuthStep.login;
                      _errorMessage = null;
                    });
                  },
                  child: const Text("Back to Login", style: TextStyle(color: Color(0xFF4A5D4E))),
                ),
              ),
            ],
          ),
        );

      case AuthStep.otp:
        return _buildGlassContainer(
          key: const ValueKey('otpInput'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Identity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E2A1F)),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter 6-digit OTP code sent to ${_phoneController.text}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'OTP Code',
                hint: '000000',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.sms_outlined, size: 20, color: Color(0xFF8A958A)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 24),
              AppLoadingButton(
                label: 'Verify & Login',
                isLoading: _isLoading,
                onPressed: () => _handleVerifyOtp(state),
                color: const Color(0xFF2D7A3A),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = AuthStep.login;
                        _errorMessage = null;
                      });
                    },
                    child: const Text("Cancel", style: TextStyle(color: Color(0xFF4A5D4E))),
                  ),
                  TextButton(
                    onPressed: () => _handleSendOtp(state),
                    child: const Text("Resend OTP", style: TextStyle(color: Color(0xFF2D7A3A), fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        );
    }
  }

  Widget _buildGlassContainer({required Key key, required Widget child}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Realistic Teardrop Painter with Fluid Dynamics ──
class DropletPainter extends CustomPainter {
  final double stretch;
  final double wobble;

  DropletPainter({required this.stretch, required this.wobble});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Rect.fromLTWH(0, 0, width, height);

    // ── 1. Shadow ──
    final shadowPath = Path();
    shadowPath.moveTo(width / 2, 4);
    shadowPath.cubicTo(width * 0.84, height * 0.44 + 4, width + 4, height * 0.74 + 4, width / 2, height + 4);
    shadowPath.cubicTo(4, height * 0.74 + 4, width * 0.16, height * 0.44 + 4, width / 2, 4);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0xFF1B5E20).withOpacity(0.25)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // ── 2. Fluid Path ──
    final path = Path();
    path.moveTo(width / 2, 0);
    path.cubicTo(width * 0.84, height * 0.42, width, height * 0.72, width / 2, height);
    path.cubicTo(0, height * 0.72, width * 0.16, height * 0.42, width / 2, 0);

    final baseGradient = RadialGradient(
      center: const Alignment(0.0, 0.20),
      radius: 0.85,
      colors: [
        const Color(0xFFC8E6C9).withOpacity(0.18),
        const Color(0xFF81C784).withOpacity(0.45),
        const Color(0xFF2E7D32).withOpacity(0.75),
      ],
      stops: const [0.0, 0.65, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = baseGradient.createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // ── 3. Stroke ──
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 4. Caustic ──
    final causticPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.45),
          const Color(0xFFA5D6A7).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(width * 0.65, height * 0.75), radius: width * 0.35));
    canvas.drawCircle(Offset(width * 0.65, height * 0.75), width * 0.35, causticPaint);

    // ── 5. Highlights ──
    canvas.drawOval(
      Rect.fromLTWH(width * 0.22, height * 0.16, width * 0.32, height * 0.22),
      Paint()..color = Colors.white.withOpacity(0.88),
    );
    canvas.drawCircle(
      Offset(width * 0.30, height * 0.38),
      width * 0.06,
      Paint()..color = Colors.white.withOpacity(0.70),
    );
  }

  @override
  bool shouldRepaint(covariant DropletPainter oldDelegate) =>
      oldDelegate.stretch != stretch || oldDelegate.wobble != wobble;
}

// ── Detailed Sitting Teardrop Painter (Logo container) ──
class SittingDropletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Rect.fromLTWH(0, 0, width, height);

    final path = Path();
    path.addOval(rect);

    // ── 1. Soft Shadow ──
    canvas.drawOval(
      Rect.fromLTWH(2, 4, width - 4, height - 2),
      Paint()
        ..color = const Color(0xFF1B5E20).withOpacity(0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // ── 2. Base Refraction Gradient ──
    final baseGradient = RadialGradient(
      center: const Alignment(0.0, 0.15),
      radius: 0.85,
      colors: [
        const Color(0xFFE8F5E9).withOpacity(0.15),
        const Color(0xFFC8E6C9).withOpacity(0.40),
        const Color(0xFF2E7D32).withOpacity(0.72),
      ],
      stops: const [0.0, 0.60, 1.0],
    );
    canvas.drawPath(
      path,
      Paint()..shader = baseGradient.createShader(rect),
    );

    // ── 3. Rim Light ──
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── 4. Caustic Focus Spot ──
    final causticPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.50),
          const Color(0xFFC8E6C9).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(width * 0.70, height * 0.70), radius: width * 0.30));
    canvas.drawCircle(Offset(width * 0.70, height * 0.70), width * 0.30, causticPaint);

    // ── 5. Specular Highlights ──
    canvas.drawOval(
      Rect.fromLTWH(width * 0.20, height * 0.15, width * 0.30, height * 0.22),
      Paint()..color = Colors.white.withOpacity(0.86),
    );
    canvas.drawCircle(
      Offset(width * 0.28, height * 0.38),
      width * 0.05,
      Paint()..color = Colors.white.withOpacity(0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Energy Dissipation Ripple ──
class RipplePainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Offset center;
  final double animationValue;

  RipplePainter({
    required this.radius,
    required this.opacity,
    required this.center,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Splash Glow
    final glowProgress = (animationValue - 0.30) / 0.18;
    if (glowProgress >= 0.0 && glowProgress <= 1.0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.7 * (1.0 - glowProgress)),
            const Color(0xFFE8F5E9).withOpacity(0.3 * (1.0 - glowProgress)),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowProgress * 80));

      canvas.drawOval(
        Rect.fromCenter(center: center, width: glowProgress * 130, height: glowProgress * 65),
        glowPaint,
      );
    }

    // 2. Splash Particle Burst
    if (glowProgress >= 0.0 && glowProgress <= 1.0) {
      final particlePaint = Paint()..style = PaintingStyle.fill;
      final numParticles = 8;

      for (int i = 0; i < numParticles; i++) {
        final double angle = (i * 2 * math.pi / numParticles) + (glowProgress * 0.45);
        final double speed = 48.0 + (i % 3) * 16.0;
        final double dist = glowProgress * speed;
        final double gravityY = glowProgress * glowProgress * 32.0;
        final double verticalOffset = -14.0 * glowProgress + gravityY;

        final Offset pPos = center + Offset(
          math.cos(angle) * dist * 1.6,
          math.sin(angle) * dist * 0.85 + verticalOffset,
        );

        final double pRadius = (1.0 - glowProgress) * 2.8;
        if (pRadius > 0.15) {
          particlePaint.shader = RadialGradient(
            colors: [
              Colors.white.withOpacity((1.0 - glowProgress) * 0.95),
              const Color(0xFF81C784).withOpacity((1.0 - glowProgress) * 0.50),
            ],
          ).createShader(Rect.fromCircle(center: pPos, radius: pRadius));
          canvas.drawCircle(pPos, pRadius, particlePaint);

          canvas.drawCircle(
            pPos - Offset(pRadius * 0.3, pRadius * 0.3),
            pRadius * 0.3,
            Paint()..color = Colors.white.withOpacity((1.0 - glowProgress) * 0.98),
          );
        }
      }
    }

    // 3. Tension ripples
    if (radius == 0 || opacity == 0) return;

    for (int i = 0; i < 3; i++) {
      final currentRadius = (radius - (i * 50)).clamp(0.0, double.infinity);
      if (currentRadius <= 0) continue;

      final currentOpacity = (opacity - (i * 0.28)).clamp(0.0, 1.0);
      if (currentOpacity <= 0) continue;

      final currentStroke = (3.2 - (radius / 220) - (i * 0.6)).clamp(0.6, 3.2);

      canvas.drawOval(
        Rect.fromCenter(center: center + const Offset(0, 1.8), width: currentRadius * 1.6, height: currentRadius * 0.85),
        Paint()
          ..color = const Color(0xFF1B5E20).withOpacity(currentOpacity * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke + 1.2,
      );

      canvas.drawOval(
        Rect.fromCenter(center: center, width: currentRadius * 1.6, height: currentRadius * 0.85),
        Paint()
          ..color = Colors.white.withOpacity(currentOpacity * 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.opacity != opacity ||
      oldDelegate.animationValue != animationValue;
}
