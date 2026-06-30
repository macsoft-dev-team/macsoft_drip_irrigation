import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

enum AuthStep { login, forgotPassword, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthStep _currentStep = AuthStep.login;
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController(text: "8888888888");
  final _passwordController = TextEditingController(text: "farmer12345");
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  static const primaryColor = Color(0xFF1E4D2B);
  static const accentColor = Color(0xFF00E676);

  Future<void> _handleLogin(AppState state) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await state.login(
      any: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!success) {
        _errorMessage = state.authError ?? "Invalid login credentials";
      }
    });
  }

  Future<void> _handleSendOtp(AppState state) async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter phone number");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await state.sendOtp(_phoneController.text.trim());
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        _currentStep = AuthStep.otp;
      } else {
        _errorMessage = state.authError ?? "Error sending OTP";
      }
    });
  }

  Future<void> _handleVerifyOtp(AppState state) async {
    if (_otpController.text.trim().length < 6) {
      setState(() => _errorMessage = "Enter 6-digit code");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await state.verifyOtp(
      _phoneController.text.trim(),
      _otpController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!success) {
        _errorMessage = state.authError ?? "Invalid OTP code";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, Color(0xFF0F3218)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.opacity,
                      size: 72,
                      color: accentColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "MACSOFT DRIP",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      "Smart Farm Monitoring & Control",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_currentStep == AuthStep.login) ...[
                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.black87),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone, color: primaryColor),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                      ),
                      const SizedBox(height: 18),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock, color: primaryColor),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter password" : null,
                      ),
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
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accentColor)))
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: primaryColor,
                              ),
                              onPressed: () => _handleLogin(state),
                              child: const Text("LOGIN AS FARMER"),
                            ),
                    ] else if (_currentStep == AuthStep.forgotPassword) ...[
                      const Text(
                        "Password Recovery",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter your phone number to request a security OTP code.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.black87),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone, color: primaryColor),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accentColor)))
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: primaryColor,
                              ),
                              onPressed: () => _handleSendOtp(state),
                              child: const Text("SEND RESET OTP"),
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = AuthStep.login;
                            _errorMessage = null;
                          });
                        },
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ] else if (_currentStep == AuthStep.otp) ...[
                      const Text(
                        "OTP Verification",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter the 6-digit OTP code sent to ${_phoneController.text}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _otpController,
                        style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: "000000",
                          hintStyle: TextStyle(color: Colors.grey, letterSpacing: 8),
                        ),
                        validator: (v) => v!.length < 6 ? "Enter 6 digits" : null,
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accentColor)))
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: primaryColor,
                              ),
                              onPressed: () => _handleVerifyOtp(state),
                              child: const Text("VERIFY & LOGIN"),
                            ),
                      const SizedBox(height: 12),
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
                            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton(
                            onPressed: () => _handleSendOtp(state),
                            child: const Text("Resend OTP", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 30),
                    const Text(
                      "Demo Mode: Enter '123456' as OTP validation code.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
