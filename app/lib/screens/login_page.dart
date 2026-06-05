import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_loading_button.dart';

enum AuthStep { splash, phoneInput, otpInput, profileSetup }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  AuthStep _currentStep = AuthStep.splash;
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

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
      if (state.user?.name?.isNotEmpty == true) {
        // Logged in user goes to home page via AppShell
      } else {
        setState(() => _currentStep = AuthStep.profileSetup);
      }
    } else {
      setState(() => _currentStep = AuthStep.phoneInput);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<AppState>().sendOtp(phone);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _currentStep = AuthStep.otpInput);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully. Try 123456.'),
          backgroundColor: Color(0xFF2D7A3A),
        ),
      );
    } else {
      setState(() => _errorMessage = 'Failed to send OTP. Try again.');
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter a valid OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loggedIn = await context.read<AppState>().verifyOtp(phone, otp);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (loggedIn) {
      // Successfully authenticated
    } else {
      final error = context.read<AppState>().authError;
      if (error == 'Need registration') {
        setState(() => _currentStep = AuthStep.profileSetup);
      } else {
        setState(() => _errorMessage = error ?? 'OTP verification failed');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<AppState>().registerFarmer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          village: _villageController.text.trim(),
          district: _districtController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      setState(() {
        _errorMessage = context.read<AppState>().authError ?? 'Failed to save profile';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final impactY = size.height * 0.40; // Droplet hits right above the form area

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

          // Subtle overlay for better text/contrast readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
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

          // ── 3. Realistic Falling Droplet with Wobble and Compression ──
          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              if (_introController.value >= 0.30) return const SizedBox.shrink();
              
              // Base scale dimensions for painter
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
                      // Brand Logo Header (pops beautifully on leaves photo)
                      if (_currentStep != AuthStep.splash) ...[
                        // Sitting droplet 3D glass container for brand icon
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
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
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
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],

                      _buildStepContent(),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case AuthStep.splash:
        return const SizedBox.shrink(); // Empty container during droplet splash

      case AuthStep.phoneInput:
        return _buildGlassContainer(
          key: const ValueKey('phoneInput'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Farmer!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2A1F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your phone number to get started with smart drip irrigation control.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter your 10-digit phone',
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
                onPressed: _sendOtp,
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        );

      case AuthStep.otpInput:
        return _buildGlassContainer(
          key: const ValueKey('otpInput'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF2D7A3A)),
                    onPressed: () => setState(() => _currentStep = AuthStep.phoneInput),
                  ),
                  const Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2A1F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit OTP code sent to ${_phoneController.text}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'OTP Code',
                hint: 'Enter 6-digit OTP',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF8A958A)),
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
                label: 'Verify OTP',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
                color: const Color(0xFF2D7A3A),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: Color(0xFF2D7A3A), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );

      case AuthStep.profileSetup:
        return _buildGlassContainer(
          key: const ValueKey('profileSetup'),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete your farm details to register and get started.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF8A958A)),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Village',
                  hint: 'Enter village name',
                  controller: _villageController,
                  validator: (v) => v == null || v.isEmpty ? 'Village is required' : null,
                  prefixIcon: const Icon(Icons.home_outlined, size: 20, color: Color(0xFF8A958A)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'District',
                        hint: 'District name',
                        controller: _districtController,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'State',
                        hint: 'State name',
                        controller: _stateController,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Pincode',
                  hint: 'Enter 6-digit postal code',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty || v.length < 6 ? 'Enter valid 6-digit pincode' : null,
                  prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20, color: Color(0xFF8A958A)),
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
                  label: 'Save Profile',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                  color: const Color(0xFF2D7A3A),
                ),
              ],
            ),
          ),
        );
    }
  }

  // Premium Frosted Glassmorphism Wrapper
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
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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

    // ── 1. Dynamic Drop Shadow on surface ──
    final shadowPath = Path();
    shadowPath.moveTo(width / 2, 4);
    shadowPath.cubicTo(
      width * 0.84,
      height * 0.44 + 4,
      width + 4,
      height * 0.74 + 4,
      width / 2,
      height + 4,
    );
    shadowPath.cubicTo(4, height * 0.74 + 4, width * 0.16, height * 0.44 + 4, width / 2, 4);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // ── 2. Refracting Liquid Teardrop Path ──
    final path = Path();
    path.moveTo(width / 2, 0);
    path.cubicTo(
      width * 0.84,
      height * 0.42,
      width,
      height * 0.72,
      width / 2,
      height,
    );
    path.cubicTo(0, height * 0.72, width * 0.16, height * 0.42, width / 2, 0);

    // Radial gradient mimics internal reflection (translucent glass core)
    final baseGradient = RadialGradient(
      center: const Alignment(0.0, 0.20),
      radius: 0.85,
      colors: [
        const Color(0xFFC8E6C9).withValues(alpha: 0.18), // transparent center
        const Color(0xFF81C784).withValues(alpha: 0.45), // body green
        const Color(0xFF2E7D32).withValues(alpha: 0.75), // dark edge contour
      ],
      stops: const [0.0, 0.65, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = baseGradient.createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // ── 3. Thin Liquid Rim Light (thickness simulation) ──
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 4. Caustic Focus Glow (focused light on bottom opposite light source) ──
    final causticPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          const Color(0xFFA5D6A7).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(width * 0.65, height * 0.75), radius: width * 0.35));
    canvas.drawCircle(Offset(width * 0.65, height * 0.75), width * 0.35, causticPaint);

    // ── 5. Primary Specular Highlight (Reflection of light source top-left) ──
    final specHighlight = Path();
    specHighlight.addOval(
      Rect.fromLTWH(width * 0.22, height * 0.16, width * 0.32, height * 0.22),
    );
    canvas.drawPath(
      specHighlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.fill,
    );

    // ── 6. Secondary Specular Highlight (Tiny pin-point reflection) ──
    canvas.drawCircle(
      Offset(width * 0.30, height * 0.38),
      width * 0.06,
      Paint()..color = Colors.white.withValues(alpha: 0.70),
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

    // ── 1. Soft Shadow on the Leaf Surface ──
    canvas.drawOval(
      Rect.fromLTWH(2, 4, width - 4, height - 2),
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // ── 2. Base Refraction Gradient (spherical lens illusion) ──
    final baseGradient = RadialGradient(
      center: const Alignment(0.0, 0.15),
      radius: 0.85,
      colors: [
        const Color(0xFFE8F5E9).withValues(alpha: 0.15), // Clear core
        const Color(0xFFC8E6C9).withValues(alpha: 0.40),
        const Color(0xFF2E7D32).withValues(alpha: 0.72), // Dark boundary edge
      ],
      stops: const [0.0, 0.60, 1.0],
    );
    canvas.drawPath(
      path,
      Paint()..shader = baseGradient.createShader(rect),
    );

    // ── 3. Specular Rim Light ──
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── 4. Caustic Focus Spot (bottom-right glow) ──
    final causticPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.50),
          const Color(0xFFC8E6C9).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(width * 0.70, height * 0.70), radius: width * 0.30));
    canvas.drawCircle(Offset(width * 0.70, height * 0.70), width * 0.30, causticPaint);

    // ── 5. Specular Highlights (Double reflection) ──
    canvas.drawOval(
      Rect.fromLTWH(width * 0.20, height * 0.15, width * 0.30, height * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );

    canvas.drawCircle(
      Offset(width * 0.28, height * 0.38),
      width * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Energy Dissipation Ripple & Glossy Particle Painter ──
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
    // 1. Splash Glow Refraction Flash
    final glowProgress = (animationValue - 0.30) / 0.18; // 0.0 to 1.0
    if (glowProgress >= 0.0 && glowProgress <= 1.0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.7 * (1.0 - glowProgress)),
            const Color(0xFFE8F5E9).withValues(alpha: 0.3 * (1.0 - glowProgress)),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowProgress * 80));

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: glowProgress * 130,
          height: glowProgress * 65,
        ),
        glowPaint,
      );
    }

    // 2. Glossy Splash Particle Burst (Glass bead simulation)
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
          math.cos(angle) * dist * 1.6, // Elliptical perspective
          math.sin(angle) * dist * 0.85 + verticalOffset,
        );

        final double pRadius = (1.0 - glowProgress) * 2.8;
        if (pRadius > 0.15) {
          // Glass volume body gradient
          particlePaint.shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: (1.0 - glowProgress) * 0.95),
              const Color(0xFF81C784).withValues(alpha: (1.0 - glowProgress) * 0.50),
            ],
          ).createShader(Rect.fromCircle(center: pPos, radius: pRadius));
          canvas.drawCircle(pPos, pRadius, particlePaint);

          // Specular white dot highlight on the bead
          final highlightPaint = Paint()
            ..color = Colors.white.withValues(alpha: (1.0 - glowProgress) * 0.98)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pPos - Offset(pRadius * 0.3, pRadius * 0.3), pRadius * 0.3, highlightPaint);
        }
      }
    }

    // 3. Elliptical tension ripples with perspective shadows
    if (radius == 0 || opacity == 0) return;

    for (int i = 0; i < 3; i++) {
      final currentRadius = (radius - (i * 50)).clamp(0.0, double.infinity);
      if (currentRadius <= 0) continue;

      final currentOpacity = (opacity - (i * 0.28)).clamp(0.0, 1.0);
      if (currentOpacity <= 0) continue;

      final currentStroke = (3.2 - (radius / 220) - (i * 0.6)).clamp(0.6, 3.2);

      // Ripple shadow for 3D leaf surface depth
      final shadowPaint = Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: currentOpacity * 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke + 1.2;

      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 1.8),
          width: currentRadius * 1.6,
          height: currentRadius * 0.85,
        ),
        shadowPaint,
      );

      // Water tension ring highlight
      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: currentOpacity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke;

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: currentRadius * 1.6,
          height: currentRadius * 0.85,
        ),
        ripplePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.opacity != opacity ||
      oldDelegate.animationValue != animationValue;
}
