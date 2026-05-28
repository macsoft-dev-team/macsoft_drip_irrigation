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

  bool _isDesktop(double width) => width >= 900;
  bool _isTablet(double width) => width >= 600 && width < 900;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final desktop = _isDesktop(size.width);

    final impactY = size.height * (desktop ? 0.38 : 0.45);

    return Scaffold(
      backgroundColor: const Color(0xFF9FB091),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg_leaves.png', fit: BoxFit.cover),
          ),

          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              if (_introController.value < 0.30) {
                return const SizedBox.shrink();
              }

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

          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              if (_introController.value >= 0.30) {
                return const SizedBox.shrink();
              }

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

          AnimatedBuilder(
            animation: _introController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _uiOpacity,
                child: SlideTransition(position: _uiSlide, child: child),
              );
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  final isDesktopScreen = _isDesktop(width);
                  final isTabletScreen = _isTablet(width);

                  final horizontalPadding = isDesktopScreen
                      ? 72.0
                      : isTabletScreen
                      ? 48.0
                      : 24.0;

                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isDesktopScreen ? 40 : 32,
                      ),
                      child: isDesktopScreen
                          ? _buildWebLayout(height)
                          : _buildMobileTabletLayout(isTabletScreen),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(double height) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1180,
        minHeight: height > 80 ? height - 80 : 0,
      ),
      child: Row(
        children: [
          Expanded(child: _buildBrandSection(isDesktop: true)),
          const SizedBox(width: 56),
          SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoginCard(isDesktop: true),
                const SizedBox(height: 24),
                _buildSupportRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(bool isTablet) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 520 : 430),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBrandSection(isDesktop: false),
          SizedBox(height: isTablet ? 36 : 32),
          _buildLoginCard(isDesktop: false),
          const SizedBox(height: 28),
          _buildSupportRow(),
        ],
      ),
    );
  }

  Widget _buildBrandSection({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logo.png',
          width: isDesktop ? 96 : 72,
          height: isDesktop ? 96 : 72,
        ),
        const SizedBox(height: 18),
        Text(
          'Smart Drip',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 52 : 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.8,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Nurture every drop.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 22 : 16,
            color: Colors.white.withOpacity(0.92),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(height: 26),
          SizedBox(
            width: 520,
            child: Text(
              'Monitor farms, manage irrigation schedules, and control field operations from one secure dashboard.',
              style: TextStyle(
                fontSize: 17,
                height: 1.6,
                color: Colors.white.withOpacity(0.88),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginCard({required bool isDesktop}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 36 : 32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isDesktop ? 36 : 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.58),
            borderRadius: BorderRadius.circular(isDesktop ? 36 : 32),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3B20).withOpacity(0.16),
                blurRadius: 42,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Login',
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3B20),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Access your irrigation dashboard',
                  style: TextStyle(fontSize: 14, color: Color(0xFF4A634D)),
                ),
                SizedBox(height: isDesktop ? 34 : 30),

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
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) {
                      return 'Enter a valid email';
                    }
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
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    if (v.length < 6) {
                      return 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }

  Widget _buildSupportRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'System offline?',
          style: TextStyle(
            color: Color(0xFF4A634D),
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3B20)),
          child: const Text(
            'Contact Admin',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class DropletPainter extends CustomPainter {
  final double stretch;

  DropletPainter({required this.stretch});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height * stretch;

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

    final gradient = RadialGradient(
      center: const Alignment(-0.2, 0.3),
      radius: 0.8,
      colors: [
        Colors.white,
        const Color(0xFFE8F5E9).withOpacity(0.9),
        const Color(0xFF81C784).withOpacity(0.5),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill,
    );

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
  bool shouldRepaint(covariant DropletPainter oldDelegate) {
    return oldDelegate.stretch != stretch;
  }
}

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

      final currentStroke = (3.0 - (radius / 250) - (i * 0.5)).clamp(0.5, 3.0);

      final paint = Paint()
        ..color = Colors.white.withOpacity(currentOpacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke;

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.opacity != opacity;
  }
}
