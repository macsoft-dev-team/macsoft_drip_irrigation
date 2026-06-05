import 'dart:ui';
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

class _LoginPageState extends State<LoginPage> {
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

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash wait
    if (!mounted) return;

    final state = context.read<AppState>();
    if (state.isAuthenticated) {
      // If authenticated but profile name is empty, go to profile setup, else home
      if (state.user?.name?.isNotEmpty == true) {
        // AppShell is loaded automatically by main.dart since isAuthenticated is true
      } else {
        setState(() => _currentStep = AuthStep.profileSetup);
      }
    } else {
      setState(() => _currentStep = AuthStep.phoneInput);
    }
  }

  @override
  void dispose() {
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
      // Successfully authenticated against backend
      // AppState handles authentication status, causing main.dart to rebuild with AppShell
    } else {
      final error = context.read<AppState>().authError;
      if (error == 'Need registration') {
        // User not registered, redirect to profile setup
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
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        children: [
          // Background graphic
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand / Logo Header
                    if (_currentStep != AuthStep.splash) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D7A3A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'DripFlow Farmer',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2A1F),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Smart Drip Irrigation SaaS Platform',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStepContent(),
                    ),
                  ],
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
        return Column(
          key: const ValueKey('splash'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.water_drop, color: Color(0xFF2D7A3A), size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'DripFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E2A1F),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFC8E6C9),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A3A)),
                minHeight: 3,
              ),
            ),
          ],
        );

      case AuthStep.phoneInput:
        return Container(
          key: const ValueKey('phoneInput'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Farmer!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your registered phone number to log in via OTP verification.',
                style: TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
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
                Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
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
        return Container(
          key: const ValueKey('otpInput'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => setState(() => _currentStep = AuthStep.phoneInput),
                  ),
                  const Text(
                    'Verify Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit OTP sent to ${_phoneController.text}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
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
                Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
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
        return Container(
          key: const ValueKey('profileSetup'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Setup',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete your farm details to get started.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
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
                  Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
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
}
