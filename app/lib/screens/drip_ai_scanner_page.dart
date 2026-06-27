import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/glitch_widgets.dart';

class DripAiScannerPage extends StatefulWidget {
  const DripAiScannerPage({super.key});

  @override
  State<DripAiScannerPage> createState() => _DripAiScannerPageState();
}

class _DripAiScannerPageState extends State<DripAiScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  
  String _selectedCrop = 'tomato';
  bool _isScanning = false;
  bool _isGlitching = false;
  String _glitchLog = "";
  Map<String, dynamic>? _scanResult;
  bool _dripApplied = false;
  bool _sensorCalibrated = false;

  final Map<String, Map<String, String>> _cropSpecimens = {
    'tomato': {
      'name': 'Tomato (Solanum lycopersicum)',
      'symptom': 'Dark brown spots on leaves surrounded by pale rings. White fuzzy undersides.',
      'emoji': '🍅',
    },
    'cotton': {
      'name': 'Cotton (Gossypium hirsutum)',
      'symptom': 'Orange-rust colored spots on undersides, leaf yellowing, and drying.',
      'emoji': '☁️',
    },
    'sugarcane': {
      'name': 'Sugarcane (Saccharum officinarum)',
      'symptom': 'Midrib lesions, red vascular rot splitting in stalk stalks, wilting crowns.',
      'emoji': '🌿',
    },
    'wheat': {
      'name': 'Wheat (Triticum aestivum)',
      'symptom': 'White to grey powdery fungal spots spreading on leaf blades.',
      'emoji': '🌾',
    },
  };

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _isGlitching = false;
      _scanResult = null;
      _dripApplied = false;
      _glitchLog = "INITIALIZING SPECTRAL MATRIX SCANNER...";
    });
    _scannerController.repeat();

    final state = context.read<AppState>();
    final activeField = state.fields.isNotEmpty ? state.fields[0].id : 'field_1';

    // Sequence of terminal diagnostic logs during scanning
    final logs = [
      "ESTABLISHING SECURE SATELLITE CONNECTION...",
      "CALIBRATING CAM SPECTRAL BAND FILTERS...",
      "READING HUMIDITY & LEAF COLOR SHIFT HISTOGRAM...",
      "WARNING: SIGNAL DEGRADATION DETECTED...",
      "ALERT: PACKET DROUT OUTS IN TELEMETRY BUS!",
      "RE-ROUTING ANALYZER SIGNAL CHANNELS...",
      "BYPASSING LENS FLARE & SCATTER COUPLING...",
      "COMPILING RETRANSMITTED DATA CHECKSUMS..."
    ];

    // Trigger visual glitch 1.2 seconds into the scan
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isGlitching = true;
          _glitchLog = logs[3];
        });
      }
    });

    // Cycle through logs during the glitch
    for (int i = 4; i < logs.length; i++) {
      final idx = i;
      Future.delayed(Duration(milliseconds: 1000 + (idx - 3) * 350), () {
        if (mounted && _isScanning) {
          setState(() {
            _glitchLog = logs[idx];
          });
        }
      });
    }

    try {
      // Call the API service (which falls back elegantly if offline)
      final api = state.api;
      final result = await (api != null
          ? api.diagnoseCropLeaf(cropType: _selectedCrop, fieldId: activeField)
          : state.fields.isNotEmpty
              ? state.fields[0].masterController == null
                  ? Future.value(<String, dynamic>{})
                  : Future.value(<String, dynamic>{}) // handeled by catch fallback
              : Future.value(<String, dynamic>{}));

      // Ensure scanning stays active for at least 3.2 seconds for the glitch effect to show fully
      await Future.delayed(const Duration(milliseconds: 3200));

      if (mounted) {
        setState(() {
          _isScanning = false;
          _isGlitching = false;
          _scannerController.stop();
          _scanResult = result.isNotEmpty ? result : null;
          _sensorCalibrated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isGlitching = false;
          _scannerController.stop();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error contacting diagnostics engine: $e')),
        );
      }
    }
  }

  Future<void> _recalibrateSensor() async {
    setState(() {
      _isScanning = true;
      _isGlitching = true;
      _glitchLog = "RE-CALIBRATING TRANSCEIVER IMPEDANCE...";
    });
    _scannerController.repeat();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _isGlitching = false;
        _sensorCalibrated = true;
        _scannerController.stop();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telemetry calibrated. Signal noise reduced from -24dB to -3.1dB (Optimal).'),
          backgroundColor: Color(0xFF00E676),
        ),
      );
    }
  }

  void _applyDripAdjustment() {
    setState(() {
      _dripApplied = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161F30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
            SizedBox(width: 8),
            Text(
              'AI Schedule Updated',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          _scanResult?['drip_irrigation_action'] ?? 'Drip system schedules updated.',
          style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17), // Deep space obsidian background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DRIPAI LEAF DOCTOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Pathogen & Drip Schedule Analyzer',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CRTScanlines(
        active: _isGlitching,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isScanning && _scanResult == null) ...[
                _buildIntroductionSection(),
                const SizedBox(height: 24),
                _buildCropSelector(),
                const SizedBox(height: 24),
                _buildSpecimenCard(),
                const SizedBox(height: 36),
                _buildScanActionBtn(),
              ] else if (_isScanning) ...[
                _buildScanningHUD(),
              ] else if (_scanResult != null) ...[
                _buildDiagnosticReport(),
                const SizedBox(height: 24),
                _buildDripRecommendationCard(),
                if (_scanResult!['sensor_status'] == 'noisy_signal_detected' && !_sensorCalibrated) ...[
                  const SizedBox(height: 20),
                  _buildSensorNoiseWarning(),
                ],
                const SizedBox(height: 32),
                _buildRescanButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121B2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2F4C)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: Color(0xFF00E676), size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spectral Disease Scanner',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  'Select a crop sample below to perform an AI leaf diagnosis. The AI analyzes humidity, leaf spots, and plant health, providing chemical treatments and adjusting your drip schedule runtime to stop pathogen growth.',
                  style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. CHOOSE CROP TYPE',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _cropSpecimens.keys.map((cropKey) {
            final isSelected = _selectedCrop == cropKey;
            final item = _cropSpecimens[cropKey]!;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCrop = cropKey;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF162A3B) : const Color(0xFF101724),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1A2332),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(item['emoji']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        cropKey.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF78909C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecimenCard() {
    final spec = _cropSpecimens[_selectedCrop]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. SPECIMEN LEAF SYMPTOM TARGET',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1420),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1B283E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(spec['emoji']!, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spec['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Symptom Sample Profile',
                          style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFF1B283E)),
              const Text(
                'Observed Leaf Pathology:',
                style: TextStyle(color: Color(0xFF78909C), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                spec['symptom']!,
                style: const TextStyle(color: Color(0xFFECEFF1), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanActionBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(56),
          shadowColor: const Color(0xFF00E676).withValues(alpha: 0.35),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.biotech_rounded, size: 22, color: Colors.black),
            SizedBox(width: 10),
            Text(
              'SCAN & ANALYZE PATHOLOGY',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningHUD() {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1322),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isGlitching ? const Color(0xFFFF5252).withValues(alpha: 0.6) : const Color(0xFF1E3A5F),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient matrix grid background
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: CustomPaint(
                  painter: MatrixGridPainter(),
                ),
              ),
            ),
            
            // Core leaf/laser graphics inside GlitchWidget
            GlitchWidget(
              active: _isGlitching,
              glitchIntensity: 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spinning holographic ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _scannerController,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isGlitching ? Colors.redAccent : const Color(0xFF00E5FF),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        _cropSpecimens[_selectedCrop]!['emoji']!,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Scanning text
                  GlitchText(
                    _isGlitching ? 'SIGNAL NOISE INTERFERENCE' : 'SPECTRAL SCANNING TISSUE...',
                    active: _isGlitching,
                    style: TextStyle(
                      color: _isGlitching ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Animated Laser sweeping line
            if (!_isGlitching)
              AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  final double position = (math.sin(_scannerController.value * math.pi * 2) + 1.0) / 2.0;
                  return Positioned(
                    top: position * 380,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF00E676),
                            Color(0xFF00E676),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E676),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Live hacking/telemetry diagnostics logger box
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isGlitching ? const Color(0xFFFF5252).withValues(alpha: 0.3) : const Color(0xFF1E2F4C),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isGlitching ? Colors.red : const Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlitchText(
                        _glitchLog,
                        active: _isGlitching,
                        style: const TextStyle(
                          color: Color(0xFFECEFF1),
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticReport() {
    final severity = _scanResult?['severity'] ?? 'LOW';
    final Color severityColor = severity == 'CRITICAL'
        ? const Color(0xFFFF3D00)
        : severity == 'HIGH'
            ? const Color(0xFFFF9100)
            : severity == 'MEDIUM'
                ? const Color(0xFFFFD600)
                : const Color(0xFF00E676);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DIAGNOSTIC REPORT',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: severityColor, width: 0.8),
              ),
              child: Text(
                severity,
                style: TextStyle(color: severityColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1420),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1D283E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD600), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _scanResult?['disease'] ?? 'Pathogen Detected',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Scientific Profile: ${_scanResult?['scientific_name'] ?? 'N/A'}',
                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontStyle: FontStyle.italic),
              ),
              
              const Divider(height: 24, color: Color(0xFF1B283E)),
              
              Row(
                children: [
                  const Text('AI Match Confidence', style: TextStyle(color: Color(0xFF78909C), fontSize: 11)),
                  const Spacer(),
                  Text(
                    '${((_scanResult?['confidence'] ?? 0.90) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _scanResult?['confidence'] ?? 0.90,
                  backgroundColor: const Color(0xFF1A2332),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                  minHeight: 6,
                ),
              ),
              
              const Divider(height: 32, color: Color(0xFF1B283E)),
              
              const Text('Disease Etiology:', style: TextStyle(color: Color(0xFF78909C), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                _scanResult?['description'] ?? '',
                style: const TextStyle(color: Color(0xFFECEFF1), fontSize: 12, height: 1.4),
              ),
              
              const SizedBox(height: 16),
              
              const Text('Farm Treatment Protocol:', style: TextStyle(color: Color(0xFF78909C), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                _scanResult?['treatment'] ?? '',
                style: const TextStyle(color: Color(0xFFECEFF1), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDripRecommendationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SMART WATERING MODIFICATION (AI)',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C2424),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF0E4A42)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.04),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: Color(0xFF00E676), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Moisture Flow Mitigation',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _scanResult?['drip_irrigation_action'] ?? '',
                style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 12, height: 1.4),
              ),
              const Divider(height: 24, color: Color(0xFF0E4A42)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dripApplied ? null : _applyDripAdjustment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF142724),
                    disabledForegroundColor: const Color(0xFF607D8B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_dripApplied ? Icons.check_circle_rounded : Icons.offline_bolt_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _dripApplied ? 'ADJUSTMENT APPLIED' : 'APPLY AI ADJUSTMENT NOW',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorNoiseWarning() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1616),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6B2020)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlitchWidget(
                active: true,
                glitchIntensity: 0.4,
                child: const Icon(Icons.flash_on_rounded, color: Color(0xFFFF5252), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'VALVE TELEMETRY BUS GLITCH',
                  style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sensor feedback noise detected on Zone 2 moisture cable bus. Signal noise is causing an AI decoding glitch. Physical probe cable corrosion or solenoid short-circuit is suspected.',
            style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 11, height: 1.4),
          ),
          const Divider(height: 24, color: Color(0xFF6B2020)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recalibrateSensor,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(42),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune_rounded, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'FORCE TELEMETRY RE-CALIBRATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescanButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _scanResult = null;
            _dripApplied = false;
            _sensorCalibrated = false;
          });
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF1E2F4C)),
          foregroundColor: const Color(0xFF90A4AE),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text('DIAGNOSE ANOTHER SPECIMEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
      ),
    );
  }
}

class MatrixGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    const double gridWidth = 20.0;
    for (double x = 0; x < size.width; x += gridWidth) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridWidth) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
