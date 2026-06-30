import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const primaryColor = Color(0xFF1E4D2B); // Deep Forest Green
  static const accentColor = Color(0xFF00E676);  // Vibrant Mint Green
  static const backgroundColor = Color(0xFFF5F7FB); // Off-White Canvas
  static const darkCardColor = Color(0xFF1A1F36);   // Sleek Dark Neutral

  @override
  Widget build(BuildContext context) {
    return FarmerAppStateProvider(
      child: MaterialApp(
        title: 'Macsoft Drip',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            primary: primaryColor,
            secondary: accentColor,
            surface: Colors.white,
            background: backgroundColor,
          ),
          scaffoldBackgroundColor: backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: primaryColor),
            titleTextStyle: TextStyle(
              color: primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            labelStyle: const TextStyle(color: primaryColor),
          ),
        ),
        home: const AppRootSelector(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE MANAGEMENT & DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ZoneModel {
  final String id;
  final String name;
  final List<String> valves;
  bool isRunning;
  int remainingMinutes;

  ZoneModel({
    required this.id,
    required this.name,
    required this.valves,
    this.isRunning = false,
    this.remainingMinutes = 0,
  });
}

class FieldModel {
  final String id;
  final String name;
  final List<ZoneModel> zones;

  FieldModel({
    required this.id,
    required this.name,
    required this.zones,
  });
}

class ScheduleModel {
  final String id;
  String name;
  String fieldId;
  String zoneId;
  String startTime;
  int durationMinutes;
  List<String> repeatDays;
  bool isActive;

  ScheduleModel({
    required this.id,
    required this.name,
    required this.fieldId,
    required this.zoneId,
    required this.startTime,
    required this.durationMinutes,
    required this.repeatDays,
    this.isActive = true,
  });
}

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String date;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.date,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}

class MessageModel {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  MessageModel({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class FarmerAppState extends ChangeNotifier {
  // Auth state
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Farm State
  String _currentFarmId = "1";
  String get currentFarmId => _currentFarmId;
  
  bool _isMasterOnline = true;
  bool get isMasterOnline => _isMasterOnline;

  double _soilMoisture = 46.0;
  double get soilMoisture => _soilMoisture;

  double _tankLevel = 82.0;
  double get tankLevel => _tankLevel;

  double _todaysWater = 1200.0;
  double get todaysWater => _todaysWater;

  // Timer simulation
  Timer? _irrigationTimer;
  String? _runningFieldId;
  String? _runningZoneId;
  int _runningRemainingSeconds = 0;

  String? get runningFieldId => _runningFieldId;
  String? get runningZoneId => _runningZoneId;
  int get runningRemainingSeconds => _runningRemainingSeconds;

  // AI assistant recommendations state
  String _aiRecommendationText = "Increase irrigation by 10 min today.";
  bool _aiRecommendationApplied = false;
  String get aiRecommendationText => _aiRecommendationText;
  bool get aiRecommendationApplied => _aiRecommendationApplied;

  // AI Assistant Chat Messages
  final List<MessageModel> _chatMessages = [
    MessageModel(text: "Hello! I am your AI Irrigation Assistant. How can I help you today?", isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
  ];
  List<MessageModel> get chatMessages => _chatMessages;

  // Leaf Scan Demo States
  bool _isScanningLeaf = false;
  String? _leafDiagnosis;
  String? _leafRecommendation;
  bool get isScanningLeaf => _isScanningLeaf;
  String? get leafDiagnosis => _leafDiagnosis;
  String? get leafRecommendation => _leafRecommendation;

  // Lists of data
  final List<FieldModel> _fields = [
    FieldModel(id: "1", name: "North Farm", zones: [
      ZoneModel(id: "101", name: "Tomato", valves: ["Valve A", "Valve D", "Valve G"]),
      ZoneModel(id: "102", name: "Banana", valves: ["Valve B", "Valve E"]),
      ZoneModel(id: "103", name: "Cotton", valves: ["Valve C", "Valve F"]),
    ]),
    FieldModel(id: "2", name: "South Farm", zones: [
      ZoneModel(id: "201", name: "Maize", valves: ["Valve H", "Valve J"]),
      ZoneModel(id: "202", name: "Sugarcane", valves: ["Valve K", "Valve L"]),
    ]),
    FieldModel(id: "3", name: "East Farm", zones: [
      ZoneModel(id: "301", name: "Rice Pad", valves: ["Valve M", "Valve N"]),
      ZoneModel(id: "302", name: "Orchard", valves: ["Valve P", "Valve R"]),
    ]),
  ];
  List<FieldModel> get fields => _fields;

  final List<ScheduleModel> _schedules = [
    ScheduleModel(id: "s1", name: "Morning Drip", fieldId: "1", zoneId: "101", startTime: "06:00 AM", durationMinutes: 30, repeatDays: ["Mon", "Wed", "Fri"]),
    ScheduleModel(id: "s2", name: "Evening Sprinkler", fieldId: "1", zoneId: "102", startTime: "06:00 PM", durationMinutes: 20, repeatDays: ["Tue", "Thu"]),
    ScheduleModel(id: "s3", name: "Weekend Flood", fieldId: "2", zoneId: "201", startTime: "08:00 AM", durationMinutes: 45, repeatDays: ["Sat", "Sun"], isActive: false),
  ];
  List<ScheduleModel> get schedules => _schedules;

  final List<NotificationModel> _notifications = [
    NotificationModel(id: "n1", title: "Master Controller Online", message: "Master device connected to server successfully.", time: "10 min ago", icon: Icons.wifi, iconColor: Colors.green),
    NotificationModel(id: "n2", title: "Tank Level Normal", message: "Water level is stable at 82%.", time: "1 hr ago", icon: Icons.water_drop, iconColor: Colors.blue),
    NotificationModel(id: "n3", title: "Schedule Started", message: "Morning Drip schedule executed on North Farm - Tomato.", time: "4 hr ago", icon: Icons.play_arrow, iconColor: Colors.teal),
  ];
  List<NotificationModel> get notifications => _notifications;

  final List<TicketModel> _tickets = [
    TicketModel(id: "t1", title: "Valve A pressure drop", description: "Getting low flow alarms on valve A even when fully open.", priority: "High", status: "Open", date: "June 28, 2026"),
    TicketModel(id: "t2", title: "Soil moisture sensor calibration", description: "Sensor 4 showing constant 10% moisture post-rain.", priority: "Medium", status: "Closed", date: "June 25, 2026"),
  ];
  List<TicketModel> get tickets => _tickets;

  // ── Actions ────────────────────────────────────────────────────────────────

  void login(String username, String password) {
    if (username.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    _stopTimer();
    notifyListeners();
  }

  void changeFarm(String id) {
    _currentFarmId = id;
    notifyListeners();
  }

  void toggleMasterStatus() {
    _isMasterOnline = !_isMasterOnline;
    addNotification(
      _isMasterOnline ? "Master Online" : "Master Offline",
      _isMasterOnline ? "Master controller back online." : "Master controller lost connection.",
      _isMasterOnline ? Icons.wifi : Icons.wifi_off,
      _isMasterOnline ? Colors.green : Colors.red,
    );
    notifyListeners();
  }

  void applyAIRecommendation() {
    _aiRecommendationApplied = true;
    // Simulate updating schedules duration
    for (var sch in _schedules) {
      if (sch.fieldId == "1" && sch.zoneId == "101") {
        sch.durationMinutes += 10;
      }
    }
    addNotification(
      "AI Recommendation Applied",
      "Tomato zone irrigation duration increased by 10 minutes.",
      Icons.bolt,
      Colors.amber,
    );
    notifyListeners();
  }

  void addNotification(String title, String message, IconData icon, Color color) {
    _notifications.insert(0, NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      time: "Just now",
      icon: icon,
      iconColor: color,
    ));
    notifyListeners();
  }

  // ── Manual Irrigation Flow ──────────────────────────────────────────

  void startIrrigation(String fieldId, String zoneId, int durationMinutes) {
    // If another is running, stop it first
    if (_irrigationTimer != null) {
      _stopTimer();
    }

    _runningFieldId = fieldId;
    _runningZoneId = zoneId;
    _runningRemainingSeconds = durationMinutes * 60;

    // Update zone status
    _setZoneRunningState(fieldId, zoneId, true, durationMinutes);

    addNotification(
      "Schedule Started",
      "Manual irrigation started on ${getZoneName(fieldId, zoneId)} for $durationMinutes min.",
      Icons.play_circle_filled,
      Colors.green,
    );

    _irrigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_runningRemainingSeconds > 0) {
        _runningRemainingSeconds--;
        // Simulate live metrics changes
        _soilMoisture = (_soilMoisture + 0.01).clamp(0.0, 100.0);
        _tankLevel = (_tankLevel - 0.005).clamp(0.0, 100.0);
        _todaysWater += 0.2;
        
        // Update remaining minutes in model
        final zm = getZoneModel(fieldId, zoneId);
        if (zm != null) {
          zm.remainingMinutes = (_runningRemainingSeconds / 60).ceil();
        }
        
        notifyListeners();
      } else {
        stopIrrigation();
      }
    });

    notifyListeners();
  }

  void stopIrrigation() {
    if (_runningFieldId != null && _runningZoneId != null) {
      addNotification(
        "Schedule Completed",
        "Irrigation completed on ${getZoneName(_runningFieldId!, _runningZoneId!)}.",
        Icons.check_circle,
        Colors.blue,
      );
      _setZoneRunningState(_runningFieldId!, _runningZoneId!, false, 0);
    }
    _stopTimer();
    notifyListeners();
  }

  void emergencyStop() {
    if (_runningFieldId != null && _runningZoneId != null) {
      addNotification(
        "Emergency Stop Triggered",
        "All valves on ${getZoneName(_runningFieldId!, _runningZoneId!)} closed immediately.",
        Icons.warning,
        Colors.red,
      );
      _setZoneRunningState(_runningFieldId!, _runningZoneId!, false, 0);
    }
    _stopTimer();
    notifyListeners();
  }

  void _stopTimer() {
    _irrigationTimer?.cancel();
    _irrigationTimer = null;
    _runningFieldId = null;
    _runningZoneId = null;
    _runningRemainingSeconds = 0;
  }

  void _setZoneRunningState(String fieldId, String zoneId, bool isRunning, int minutes) {
    for (var f in _fields) {
      for (var z in f.zones) {
        if (f.id == fieldId && z.id == zoneId) {
          z.isRunning = isRunning;
          z.remainingMinutes = minutes;
        } else {
          z.isRunning = false;
          z.remainingMinutes = 0;
        }
      }
    }
  }

  // ── Schedules CRUD ─────────────────────────────────────────────────────────

  void addSchedule(ScheduleModel sch) {
    _schedules.add(sch);
    notifyListeners();
  }

  void updateSchedule(ScheduleModel sch) {
    final idx = _schedules.indexWhere((element) => element.id == sch.id);
    if (idx != -1) {
      _schedules[idx] = sch;
      notifyListeners();
    }
  }

  void toggleScheduleActive(String id) {
    final sch = _schedules.firstWhere((element) => element.id == id);
    sch.isActive = !sch.isActive;
    notifyListeners();
  }

  void deleteSchedule(String id) {
    _schedules.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  // ── Tickets ────────────────────────────────────────────────────────────────

  void addTicket(String title, String description, String priority) {
    _tickets.insert(0, TicketModel(
      id: "t${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      description: description,
      priority: priority,
      status: "Open",
      date: "Today",
    ));
    notifyListeners();
  }

  // ── AI Leaf Scanner Simulation ─────────────────────────────────────────────

  void startLeafScanSimulation() {
    _isScanningLeaf = true;
    _leafDiagnosis = null;
    _leafRecommendation = null;
    notifyListeners();

    Timer(const Duration(seconds: 2), () {
      _isScanningLeaf = false;
      _leafDiagnosis = "Tomato Leaf Mold (Passalora fulva)";
      _leafRecommendation = "Improve ventilation. Apply a copper-based fungicide. Avoid overhead watering to keep foliage dry.";
      notifyListeners();
    });
  }

  // ── Chat AI Simulation ─────────────────────────────────────────────────────

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;

    _chatMessages.add(MessageModel(text: text, isMe: true, timestamp: DateTime.now()));
    notifyListeners();

    // AI simulated response
    Timer(const Duration(milliseconds: 1200), () {
      String reply = "I'm analyzing your request. ";
      final query = text.toLowerCase();
      if (query.contains("moisture") || query.contains("soil")) {
        reply = "Your current soil moisture is $soilMoisture%. For Tomatoes, the ideal range is 50%-70%. I recommend applying a short 10-minute irrigation cycle.";
      } else if (query.contains("tank")) {
        reply = "Your tank level is at $tankLevel%. This is sufficient for approximately 4 more complete cycles on your fields.";
      } else if (query.contains("valve") || query.contains("failure")) {
        reply = "To troubleshoot valve issues, check if the slave board unit is responding over the network and that the 24VAC solenoid coils have correct resistance (20-60 ohms).";
      } else if (query.contains("hello") || query.contains("hi")) {
        reply = "Hello John! How can I help you manage North Farm or adjust irrigation schedules today?";
      } else {
        reply = "Understood. For Phase 1, you can monitor soil moisture ($soilMoisture%), check the Master controller status, or trigger quick irrigation directly from the home dashboard.";
      }

      _chatMessages.add(MessageModel(text: reply, isMe: false, timestamp: DateTime.now()));
      notifyListeners();
    });
  }

  // ── Helper Getters ─────────────────────────────────────────────────────────

  String getFieldName(String fieldId) {
    try {
      return _fields.firstWhere((element) => element.id == fieldId).name;
    } catch (_) {
      return "Unknown Farm";
    }
  }

  String getZoneName(String fieldId, String zoneId) {
    try {
      final f = _fields.firstWhere((element) => element.id == fieldId);
      return f.zones.firstWhere((element) => element.id == zoneId).name;
    } catch (_) {
      return "Unknown Zone";
    }
  }

  ZoneModel? getZoneModel(String fieldId, String zoneId) {
    try {
      final f = _fields.firstWhere((element) => element.id == fieldId);
      return f.zones.firstWhere((element) => element.id == zoneId);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INHERITED NOTIFIER PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class FarmerAppStateProvider extends StatefulWidget {
  final Widget child;
  const FarmerAppStateProvider({super.key, required this.child});

  @override
  State<FarmerAppStateProvider> createState() => _FarmerAppStateProviderState();
}

class _FarmerAppStateProviderState extends State<FarmerAppStateProvider> {
  late FarmerAppState _state;

  @override
  void initState() {
    super.initState();
    _state = FarmerAppState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FarmerAppStateScope(
      notifier: _state,
      child: widget.child,
    );
  }
}

class FarmerAppStateScope extends InheritedNotifier<FarmerAppState> {
  const FarmerAppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static FarmerAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FarmerAppStateScope>();
    if (scope == null) {
      throw Exception("FarmerAppStateScope not found in context");
    }
    return scope.notifier!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SCREEN ROUTING SELECTOR
// ─────────────────────────────────────────────────────────────────────────────

class AppRootSelector extends StatelessWidget {
  const AppRootSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    return state.isAuthenticated ? const AppShell() : const LoginScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHENTICATION SCREENS (LOGIN, FORGOT PASSWORD, OTP)
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: "+91 98765 43210");
  final _passController = TextEditingController(text: "password123");
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MyApp.primaryColor, Color(0xFF0F3218)],
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
                      color: MyApp.accentColor,
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
                    const SizedBox(height: 48),
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone, color: MyApp.primaryColor),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                    ),
                    const SizedBox(height: 18),
                    // Password Field
                    TextFormField(
                      controller: _passController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock, color: MyApp.primaryColor),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter password" : null,
                    ),
                    const SizedBox(height: 12),
                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: MyApp.accentColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyApp.accentColor,
                        foregroundColor: MyApp.primaryColor,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          state.login(_phoneController.text, _passController.text);
                        }
                      },
                      child: const Text("LOGIN AS FARMER"),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Phase 1 Demo • Secure Connection",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.lock_reset, size: 64, color: MyApp.primaryColor),
              const SizedBox(height: 24),
              const Text(
                "Enter your registered phone number. We will send you an OTP to verify identity.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone),
                  hintText: "+91 XXXXX XXXXX",
                ),
                validator: (v) => v!.isEmpty ? "Please enter phone number" : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => OtpVerificationScreen(phone: _phoneController.text),
                      ),
                    );
                  }
                },
                child: const Text("SEND OTP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.sms, size: 64, color: MyApp.primaryColor),
              const SizedBox(height: 24),
              Text(
                "Enter the 6-digit OTP code sent to ${widget.phone}",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: "000000",
                ),
                validator: (v) => v!.length < 6 ? "Enter 6-digit code" : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Simulate successful verify & login
                    state.login(widget.phone, "dummy");
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                child: const Text("VERIFY & LOG IN"),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("OTP Resent successfully!")),
                  );
                },
                child: const Text(
                  "Resend Code",
                  style: TextStyle(color: MyApp.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SHELL CONTAINER (NAVIGATION INCLUDES APPBAR & TABS)
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const IrrigationScreen(),
    const ScheduleListScreen(),
    const AiAssistantScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.opacity, color: MyApp.primaryColor),
            const SizedBox(width: 8),
            Text(_currentIndex == 0 ? "MACSOFT DRIP" : _getTitle(_currentIndex)),
          ],
        ),
        actions: [
          // Notifications Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const NotificationsScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SupportScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: MyApp.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), activeIcon: Icon(Icons.water_drop), label: "Irrigation"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: "AI Assistant"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return "Manual Irrigation";
      case 2:
        return "Schedules";
      case 3:
        return "Drip AI";
      case 4:
        return "My Profile";
      default:
        return "";
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: HOME DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    final activeFarm = state.fields.firstWhere((e) => e.id == state.currentFarmId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome & Farm Selector Card
          _buildGreetingSection(context, state),
          const SizedBox(height: 16),

          // Master Status Row
          _buildMasterStatusCard(state),
          const SizedBox(height: 16),

          // Core Metrics Dashboard (2x2 Grid)
          _buildLiveTelemetryGrid(state),
          const SizedBox(height: 16),

          // UX RECOMMENDATION: Quick Start Irrigation Card
          _buildQuickStartCard(context, state),
          const SizedBox(height: 16),

          // Farms/Fields List
          _buildFieldsSection(context, state),
          const SizedBox(height: 16),

          // AI Recommendation Widget
          _buildAIRecommendationWidget(state),
          const SizedBox(height: 16),

          // Recent Alerts Widget
          _buildRecentAlertsSection(context, state),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context, FarmerAppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MyApp.primaryColor, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MyApp.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Good Morning 👋",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Text(
                "John",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          // Dropdown Selector for Fields/Farms
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.currentFarmId,
                dropdownColor: MyApp.primaryColor,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                items: state.fields.map((f) {
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text(f.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) state.changeFarm(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterStatusCard(FarmerAppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (state.isMasterOnline ? Colors.green : Colors.red).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isMasterOnline ? Icons.wifi : Icons.wifi_off,
                color: state.isMasterOnline ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Master Hub Status",
                    style: TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    state.isMasterOnline ? "🟢 Online" : "🔴 Offline",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
            // Switch for simulating hardware connectivity changes
            Switch(
              value: state.isMasterOnline,
              activeColor: MyApp.accentColor,
              onChanged: (val) {
                state.toggleMasterStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTelemetryGrid(FarmerAppState state) {
    final activeFarm = state.fields.firstWhere((e) => e.id == state.currentFarmId);
    String runningZoneText = "None";
    String remainingText = "--";

    if (state.runningFieldId == state.currentFarmId && state.runningZoneId != null) {
      runningZoneText = state.getZoneName(state.runningFieldId!, state.runningZoneId!);
      int mins = (state.runningRemainingSeconds / 60).ceil();
      remainingText = "$mins Min";
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Tank Card
            _buildTelemetryTile(
              width: cardWidth,
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              title: "Tank Level",
              value: "${state.tankLevel.toStringAsFixed(0)}%",
              subtitle: "Sensor Normal",
            ),
            // Moisture Card
            _buildTelemetryTile(
              width: cardWidth,
              icon: Icons.grass,
              iconColor: Colors.orange,
              title: "Soil Moisture",
              value: "${state.soilMoisture.toStringAsFixed(0)}%",
              subtitle: "Low (Target 55%)",
            ),
            // Today's Water Card
            _buildTelemetryTile(
              width: cardWidth,
              icon: Icons.analytics,
              iconColor: Colors.teal,
              title: "Today's Water",
              value: "${state.todaysWater.toStringAsFixed(0)} L",
              subtitle: "Drip flow speed",
            ),
            // Running Zone Card
            _buildTelemetryTile(
              width: cardWidth,
              icon: Icons.timer,
              iconColor: state.runningZoneId != null ? Colors.green : Colors.grey,
              title: "Running Zone",
              value: runningZoneText,
              subtitle: state.runningZoneId != null ? "Remaining: $remainingText" : "Idle state",
            ),
          ],
        );
      },
    );
  }

  Widget _buildTelemetryTile({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: iconColor.darken(0.2), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context, FarmerAppState state) {
    // Current Selected Farm Zones
    final activeFarm = state.fields.firstWhere((e) => e.id == state.currentFarmId);
    
    return QuickStartIrrigationCard(
      field: activeFarm,
      state: state,
    );
  }

  Widget _buildFieldsSection(BuildContext context, FarmerAppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Fields / Zones Monitor",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.fields.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final f = state.fields[index];
            bool isFarmRunning = state.runningFieldId == f.id;

            return Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isFarmRunning ? MyApp.accentColor : MyApp.primaryColor).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.landscape,
                    color: isFarmRunning ? Colors.green : MyApp.primaryColor,
                  ),
                ),
                title: Text(
                  f.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${f.zones.length} Zones configured"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFarmRunning)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "RUNNING",
                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => FieldDetailScreen(field: f),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAIRecommendationWidget(FarmerAppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MyApp.darkCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: MyApp.accentColor),
              const SizedBox(width: 8),
              Text(
                "AI Recommendations",
                style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.aiRecommendationText,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              state.aiRecommendationApplied
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text("Applied Successfully", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: MyApp.accentColor),
                        foregroundColor: MyApp.accentColor,
                      ),
                      onPressed: () {
                        state.applyAIRecommendation();
                      },
                      child: const Text("Apply Recommendation"),
                    ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentAlertsSection(BuildContext context, FarmerAppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Alerts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const NotificationsScreen()),
                );
              },
              child: const Text("View All", style: TextStyle(color: MyApp.primaryColor)),
            )
          ],
        ),
        const SizedBox(height: 4),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (state.notifications.length > 2) ? 2 : state.notifications.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final alert = state.notifications[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(alert.icon, color: alert.iconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(alert.message, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(alert.time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN CUSTOM CARD: QUICK START IRRIGATION WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class QuickStartIrrigationCard extends StatefulWidget {
  final FieldModel field;
  final FarmerAppState state;

  const QuickStartIrrigationCard({
    super.key,
    required this.field,
    required this.state,
  });

  @override
  State<QuickStartIrrigationCard> createState() => _QuickStartIrrigationCardState();
}

class _QuickStartIrrigationCardState extends State<QuickStartIrrigationCard> {
  String? _selectedZoneId;
  int _selectedDuration = 15; // default 15 mins

  @override
  void initState() {
    super.initState();
    if (widget.field.zones.isNotEmpty) {
      _selectedZoneId = widget.field.zones.first.id;
    }
  }

  @override
  void didUpdateWidget(QuickStartIrrigationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If farm changed, reset selected zone
    if (oldWidget.field.id != widget.field.id) {
      if (widget.field.zones.isNotEmpty) {
        _selectedZoneId = widget.field.zones.first.id;
      } else {
        _selectedZoneId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isRunning = state.runningFieldId != null && state.runningZoneId != null;

    if (isRunning) {
      final runningZoneName = state.getZoneName(state.runningFieldId!, state.runningZoneId!);
      final runningFieldName = state.getFieldName(state.runningFieldId!);
      final pct = 1.0 - (state.runningRemainingSeconds / (15 * 60)); // simulation percent
      final int minutesLeft = (state.runningRemainingSeconds / 60).ceil();

      return Card(
        color: MyApp.primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.white, size: 26),
                      SizedBox(width: 8),
                      Text(
                        "IRRIGATING LIVE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                      ),
                    ],
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: MyApp.accentColor, shape: BoxShape.circle),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "$runningFieldName • $runningZoneName Zone",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Watering in progress. Remaining time: $minutesLeft minutes",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              // Linear loading line
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(MyApp.accentColor),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        state.stopIrrigation();
                      },
                      child: const Text("STOP CYCLE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        state.emergencyStop();
                      },
                      child: const Text("EMERGENCY STOP", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: MyApp.primaryColor),
                SizedBox(width: 8),
                Text(
                  "Quick Start Irrigation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MyApp.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.field.zones.isEmpty)
              const Text("No zones configured for this farm.")
            else ...[
              // Zone dropdown selector
              const Text("Select Zone", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZoneId,
                    isExpanded: true,
                    items: widget.field.zones.map((z) {
                      return DropdownMenuItem<String>(
                        value: z.id,
                        child: Text(z.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedZoneId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Duration slider or chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Duration", style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                  Text(
                    "$_selectedDuration Min",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: MyApp.primaryColor),
                  ),
                ],
              ),
              Slider(
                value: _selectedDuration.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                activeColor: MyApp.primaryColor,
                inactiveColor: Colors.grey.shade200,
                onChanged: (val) {
                  setState(() {
                    _selectedDuration = val.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [5, 10, 15, 30, 45, 60].map((mins) {
                  bool isSel = _selectedDuration == mins;
                  return ChoiceChip(
                    label: Text("$mins m"),
                    selected: isSel,
                    selectedColor: MyApp.primaryColor,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = mins;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  if (_selectedZoneId != null) {
                    state.startIrrigation(widget.field.id, _selectedZoneId!, _selectedDuration);
                  }
                },
                child: const Text("START IRRIGATION NOW"),
              )
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN: FIELDS & DETAILS & ZONES & VALVE STATUSES
// ─────────────────────────────────────────────────────────────────────────────

class FieldDetailScreen extends StatelessWidget {
  final FieldModel field;
  const FieldDetailScreen({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    bool isFarmRunning = state.runningFieldId == field.id;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(field.name),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: MyApp.primaryColor,
            labelColor: MyApp.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Zones"),
              Tab(text: "Monitoring"),
              Tab(text: "Schedules"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context, state),
            _buildZonesTab(context, state),
            _buildMonitoringTab(state),
            _buildSchedulesTab(context, state),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, FarmerAppState state) {
    bool isFarmRunning = state.runningFieldId == field.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Icon(Icons.landscape, size: 48, color: MyApp.primaryColor),
                const SizedBox(height: 12),
                Text(field.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Irrigation Area: 12.5 Acres • Soil: Clay Loam", style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewIndicator("Master Controller", state.isMasterOnline ? "🟢 Online" : "🔴 Offline"),
                    _buildOverviewIndicator("Running Zone", isFarmRunning ? state.getZoneName(state.runningFieldId!, state.runningZoneId!) : "None"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewIndicator("Water Used Today", "${state.todaysWater.toStringAsFixed(0)} Liters"),
                    _buildOverviewIndicator("Pressure Status", "2.4 Bar (Stable)"),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOverviewIndicator(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildZonesTab(BuildContext context, FarmerAppState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: field.zones.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final z = field.zones[idx];
        bool isThisRunning = state.runningFieldId == field.id && state.runningZoneId == z.id;
        
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.grid_on,
              color: isThisRunning ? Colors.green : Colors.grey,
              size: 28,
            ),
            title: Text(z.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${z.valves.length} Physical Valves: ${z.valves.join(', ')}"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isThisRunning ? Colors.green : Colors.grey.shade100).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isThisRunning ? "RUNNING" : "STOPPED",
                style: TextStyle(
                  color: isThisRunning ? Colors.green : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ZoneDetailScreen(field: field, zone: z),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMonitoringTab(FarmerAppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonitorRow("Tank Water Level", "${state.tankLevel.toStringAsFixed(1)} %", Icons.water_drop, Colors.blue),
          _buildMonitorRow("Soil Moisture Average", "${state.soilMoisture.toStringAsFixed(1)} %", Icons.grass, Colors.orange),
          _buildMonitorRow("System Water Pressure", "2.4 Bar", Icons.speed, Colors.purple),
          _buildMonitorRow("Drip Flow Rate", "14.2 L/min", Icons.compare_arrows, Colors.teal),
          _buildMonitorRow("Master Hub Heartbeat", state.isMasterOnline ? "100% Connected" : "Disconnected", Icons.wifi, Colors.green),
          _buildMonitorRow("Slaves RSSI Signal Strength", "Excellent (-64 dBm)", Icons.settings_input_antenna, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildMonitorRow(String name, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
        ),
      ),
    );
  }

  Widget _buildSchedulesTab(BuildContext context, FarmerAppState state) {
    final list = state.schedules.where((element) => element.fieldId == field.id).toList();

    if (list.isEmpty) {
      return const Center(child: Text("No schedules configured for this field."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final sch = list[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(sch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${state.getZoneName(sch.fieldId, sch.zoneId)} • Start: ${sch.startTime} • ${sch.durationMinutes} min\nDays: ${sch.repeatDays.join(', ')}"),
            trailing: Switch(
              value: sch.isActive,
              activeColor: MyApp.accentColor,
              onChanged: (val) {
                state.toggleScheduleActive(sch.id);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHistoryItem("Yesterday", "Tomato Zone", "45 Minutes irrigation cycle", "1,800 Liters", true),
        _buildHistoryItem("Monday, June 29", "Banana Zone", "20 Minutes irrigation cycle", "950 Liters", true),
        _buildHistoryItem("Sunday, June 28", "Cotton Zone", "30 Minutes irrigation cycle", "1,200 Liters", true),
        _buildHistoryItem("Thursday, June 25", "Tomato Zone", "45 Minutes irrigation cycle", "1,800 Liters", true),
        _buildHistoryItem("Wednesday, June 24", "Tomato Zone", "20 Minutes (Aborted - Flow High)", "780 Liters", false),
      ],
    );
  }

  Widget _buildHistoryItem(String day, String zone, String desc, String water, bool success) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: success ? Colors.green : Colors.red,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(zone, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(day, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(desc, style: const TextStyle(fontSize: 12)),
            Text(water, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: MyApp.primaryColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ZONE DETAILS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ZoneDetailScreen extends StatefulWidget {
  final FieldModel field;
  final ZoneModel zone;
  const ZoneDetailScreen({super.key, required this.field, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  int _selectedMins = 15;

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    bool isRunning = state.runningFieldId == widget.field.id && state.runningZoneId == widget.zone.id;
    int minsRemaining = isRunning ? (state.runningRemainingSeconds / 60).ceil() : 0;

    return Scaffold(
      appBar: AppBar(title: Text("${widget.zone.name} Details")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isRunning ? Colors.green.withOpacity(0.08) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isRunning ? Colors.green.withOpacity(0.3) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    isRunning ? Icons.play_circle_filled : Icons.pause_circle_filled,
                    size: 64,
                    color: isRunning ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRunning ? "STATUS: RUNNING" : "STATUS: IDLE / STOPPED",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? Colors.green : Colors.black87,
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Remaining duration: $minsRemaining Minutes",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Valves Configuration List (Read-only)
            const Text(
              "Zone Output Valves Configuration",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.zone.valves.length,
                itemBuilder: (context, idx) {
                  final v = widget.zone.valves[idx];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.settings_input_component, color: MyApp.primaryColor),
                      title: Text(v),
                      trailing: Text(
                        isRunning ? "🟢 OPEN" : "🔴 CLOSED",
                        style: TextStyle(
                          color: isRunning ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Start/Stop controller
            if (!isRunning) ...[
              const Text("Select Irrigation Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [10, 20, 30, 45].map((t) {
                  bool isSel = _selectedMins == t;
                  return ChoiceChip(
                    label: Text("$t Min"),
                    selected: isSel,
                    selectedColor: MyApp.primaryColor,
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMins = t;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  state.startIrrigation(widget.field.id, widget.zone.id, _selectedMins);
                },
                child: const Text("START ZONE IRRIGATION"),
              ),
            ] else ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  state.stopIrrigation();
                },
                child: const Text("STOP ZONE IRRIGATION"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  state.emergencyStop();
                },
                child: const Text("EMERGENCY STOP"),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: MANUAL IRRIGATION FLOW WIZARD
// ─────────────────────────────────────────────────────────────────────────────

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  String? _selectedFieldId;
  String? _selectedZoneId;
  int _selectedMins = 15;

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    final isRunning = state.runningFieldId != null && state.runningZoneId != null;

    if (isRunning) {
      final runningZoneName = state.getZoneName(state.runningFieldId!, state.runningZoneId!);
      final runningFieldName = state.getFieldName(state.runningFieldId!);
      final minutesRemaining = (state.runningRemainingSeconds / 60).ceil();
      final totalSeconds = 15 * 60; // simulated total
      
      return Container(
        padding: const EdgeInsets.all(28.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LiveIrrigationPulsar(),
            const SizedBox(height: 36),
            Text(
              runningZoneName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: MyApp.primaryColor),
            ),
            Text(
              "Active in $runningFieldName",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Remaining", "$minutesRemaining min"),
                  _buildStatColumn("Flow Rate", "14.2 L/min"),
                  _buildStatColumn("Pressure", "2.4 Bar"),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () {
                state.stopIrrigation();
              },
              child: const Text("STOP IRRIGATION"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () {
                state.emergencyStop();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text("EMERGENCY STOP"),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Step-by-step Setup Form
    final fields = state.fields;
    final activeField = _selectedFieldId == null 
        ? fields.first 
        : fields.firstWhere((element) => element.id == _selectedFieldId);

    if (_selectedFieldId == null) {
      _selectedFieldId = activeField.id;
    }
    if (_selectedZoneId == null && activeField.zones.isNotEmpty) {
      _selectedZoneId = activeField.zones.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Configure Manual Irrigation Cycle",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
          ),
          const SizedBox(height: 4),
          const Text("Open custom valves on demand instantly.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 28),

          // 1. Select Field
          const Text("1. Select Field/Farm Location", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Column(
            children: fields.map((f) {
              bool isSelected = _selectedFieldId == f.id;
              return Card(
                color: isSelected ? MyApp.primaryColor : Colors.white,
                child: ListTile(
                  title: Text(
                    f.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: MyApp.accentColor) : null,
                  onTap: () {
                    setState(() {
                      _selectedFieldId = f.id;
                      _selectedZoneId = f.zones.isNotEmpty ? f.zones.first.id : null;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 2. Select Zone
          const Text("2. Select Zone Target", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (activeField.zones.isEmpty)
            const Text("No zones available in this field.")
          else
            DropdownButtonFormField<String>(
              value: _selectedZoneId,
              decoration: const InputDecoration(labelText: "Zone"),
              items: activeField.zones.map((z) {
                return DropdownMenuItem<String>(
                  value: z.id,
                  child: Text(z.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedZoneId = val;
                });
              },
            ),
          const SizedBox(height: 24),

          // 3. Select Duration
          const Text("3. Select Watering Duration", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [5, 10, 15, 30, 45, 60].map<Widget>((t) {
              bool isSel = _selectedMins == t;
              return ChoiceChip(
                label: Text("$t Min"),
                selected: isSel,
                selectedColor: MyApp.primaryColor,
                labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                onSelected: (bool selected) {
                  setState(() {
                    _selectedMins = t;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          ElevatedButton(
            onPressed: () {
              if (_selectedFieldId != null && _selectedZoneId != null) {
                state.startIrrigation(_selectedFieldId!, _selectedZoneId!, _selectedMins);
              }
            },
            child: const Text("START IRRIGATION VALVE"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyApp.primaryColor)),
      ],
    );
  }
}

class LiveIrrigationPulsar extends StatefulWidget {
  const LiveIrrigationPulsar({super.key});

  @override
  State<LiveIrrigationPulsar> createState() => _LiveIrrigationPulsarState();
}

class _LiveIrrigationPulsarState extends State<LiveIrrigationPulsar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MyApp.primaryColor.withOpacity(0.05),
            border: Border.all(
              color: MyApp.primaryColor.withOpacity(1.0 - _controller.value),
              width: _controller.value * 20,
            ),
          ),
          child: const Center(
            child: Icon(Icons.water, size: 64, color: MyApp.primaryColor),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: SCHEDULES MANAGER (LIST & CREATE/EDIT FORM)
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleListScreen extends StatelessWidget {
  const ScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);

    return Scaffold(
      body: state.schedules.isEmpty
          ? const Center(child: Text("No schedules configured yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.schedules.length,
              itemBuilder: (context, idx) {
                final s = state.schedules[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (s.isActive ? MyApp.primaryColor : Colors.grey).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.alarm,
                        color: s.isActive ? MyApp.primaryColor : Colors.grey,
                      ),
                    ),
                    title: Text(
                      s.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: s.isActive ? Colors.black87 : Colors.black45,
                      ),
                    ),
                    subtitle: Text(
                      "${state.getFieldName(s.fieldId)} • ${state.getZoneName(s.fieldId, s.zoneId)}\nStart: ${s.startTime} • Duration: ${s.durationMinutes} min\nDays: ${s.repeatDays.join(', ')}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle Status Switch
                        Switch(
                          value: s.isActive,
                          activeColor: MyApp.accentColor,
                          onChanged: (val) {
                            state.toggleScheduleActive(s.id);
                          },
                        ),
                        // Actions Menu
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => ScheduleFormScreen(schedule: s),
                                ),
                              );
                            } else if (action == 'delete') {
                              _confirmDelete(context, state, s.id);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(value: 'edit', child: Text("Edit")),
                            const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const ScheduleFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FarmerAppState state, String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Schedule"),
        content: const Text("Are you sure you want to delete this irrigation schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              state.deleteSchedule(id);
              Navigator.pop(c);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ScheduleFormScreen extends StatefulWidget {
  final ScheduleModel? schedule;
  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _fieldId;
  late String _zoneId;
  late String _startTime;
  late int _durationMinutes;
  late List<String> _repeatDays;

  final List<String> _weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      final s = widget.schedule!;
      _name = s.name;
      _fieldId = s.fieldId;
      _zoneId = s.zoneId;
      _startTime = s.startTime;
      _durationMinutes = s.durationMinutes;
      _repeatDays = List.from(s.repeatDays);
    } else {
      _name = "New Drip Schedule";
      _fieldId = "1";
      _zoneId = "101";
      _startTime = "07:00 AM";
      _durationMinutes = 15;
      _repeatDays = ["Mon", "Wed", "Fri"];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);
    final activeField = state.fields.firstWhere((e) => e.id == _fieldId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.schedule == null ? "Create Schedule" : "Edit Schedule")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: "Schedule Name"),
                validator: (v) => v!.isEmpty ? "Enter schedule name" : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 20),

              // Field Selection
              DropdownButtonFormField<String>(
                value: _fieldId,
                decoration: const InputDecoration(labelText: "Farm Field"),
                items: state.fields.map((f) {
                  return DropdownMenuItem<String>(value: f.id, child: Text(f.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _fieldId = val;
                      final f = state.fields.firstWhere((element) => element.id == val);
                      _zoneId = f.zones.isNotEmpty ? f.zones.first.id : "";
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Zone Selection
              DropdownButtonFormField<String>(
                value: _zoneId.isEmpty ? null : _zoneId,
                decoration: const InputDecoration(labelText: "Irrigation Zone"),
                items: activeField.zones.map((z) {
                  return DropdownMenuItem<String>(value: z.id, child: Text(z.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _zoneId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Start Time
              ListTile(
                title: const Text("Start Time", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_startTime, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = time.format(context);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Duration
              TextFormField(
                initialValue: _durationMinutes.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Duration (Minutes)"),
                validator: (v) => int.tryParse(v!) == null ? "Enter valid number" : null,
                onSaved: (v) => _durationMinutes = int.parse(v!),
              ),
              const SizedBox(height: 24),

              // Repeat Days
              const Text("Repeat Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekdays.map((day) {
                  bool isSel = _repeatDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSel,
                    selectedColor: MyApp.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _repeatDays.add(day);
                        } else {
                          _repeatDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    
                    final newSch = ScheduleModel(
                      id: widget.schedule?.id ?? "s${DateTime.now().millisecondsSinceEpoch}",
                      name: _name,
                      fieldId: _fieldId,
                      zoneId: _zoneId,
                      startTime: _startTime,
                      durationMinutes: _durationMinutes,
                      repeatDays: _repeatDays,
                      isActive: widget.schedule?.isActive ?? true,
                    );

                    if (widget.schedule == null) {
                      state.addSchedule(newSch);
                    } else {
                      state.updateSchedule(newSch);
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text("SAVE SCHEDULE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: AI ASSISTANT (CHAT DIALOGUE, LEAF SCANNER DIAGNOSIS)
// ─────────────────────────────────────────────────────────────────────────────

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  int _aiSubTab = 0; // 0 = Assistant Home, 1 = Leaf Scanner, 2 = Chat AI
  final _chatInputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubTabButton(0, "AI Home", Icons.auto_awesome),
              _buildSubTabButton(1, "Leaf Scan", Icons.center_focus_strong),
              _buildSubTabButton(2, "Ask AI Chat", Icons.chat),
            ],
          ),
        ),
      ),
      body: _buildSelectedSubScreen(state),
    );
  }

  Widget _buildSubTabButton(int idx, String title, IconData icon) {
    bool isSel = _aiSubTab == idx;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: isSel ? MyApp.primaryColor : Colors.grey,
      ),
      icon: Icon(icon, color: isSel ? MyApp.primaryColor : Colors.grey),
      label: Text(
        title,
        style: TextStyle(
          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          color: isSel ? MyApp.primaryColor : Colors.grey,
        ),
      ),
      onPressed: () {
        setState(() {
          _aiSubTab = idx;
        });
      },
    );
  }

  Widget _buildSelectedSubScreen(FarmerAppState state) {
    switch (_aiSubTab) {
      case 0:
        return _buildAiHome(state);
      case 1:
        return _buildLeafScan(state);
      case 2:
        return _buildChatInterface(state);
      default:
        return Container();
    }
  }

  Widget _buildAiHome(FarmerAppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Today's AI Recommendation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
          ),
          const SizedBox(height: 12),
          Card(
            color: MyApp.darkCardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.spa, color: MyApp.accentColor),
                      SizedBox(width: 8),
                      Text("Tomato Zone Target", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Moisture Level: 46% (Below optimal 55%)",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Increase irrigation duration by 10 minutes for the morning shift to restore soil saturation.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text("Confidence: 92%", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text("Ignore", style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyApp.accentColor,
                              foregroundColor: MyApp.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: state.aiRecommendationApplied ? null : () {
                              state.applyAIRecommendation();
                            },
                            child: Text(state.aiRecommendationApplied ? "Applied" : "Apply"),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Quick Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildShortcutCard(
                  Icons.center_focus_strong,
                  "Diagnose Crops",
                  "Use camera scan to detect diseases",
                  () => setState(() => _aiSubTab = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShortcutCard(
                  Icons.chat_bubble_outline,
                  "Irrigation Chatbot",
                  "Query weather & dynamic telemetry",
                  () => setState(() => _aiSubTab = 2),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildShortcutCard(IconData icon, String title, String subtitle, VoidCallback tap) {
    return Card(
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: MyApp.primaryColor, size: 32),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeafScan(FarmerAppState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "AI Crop Leaf Diagnosis",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            "Scan leaves instantly to detect infections.",
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: state.isScanningLeaf
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: MyApp.primaryColor),
                          SizedBox(height: 16),
                          Text("AI Diagnosing Uploaded Scan...", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : state.leafDiagnosis != null
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 54),
                              const SizedBox(height: 16),
                              Text(
                                "Diagnosis: ${state.leafDiagnosis}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.leafRecommendation ?? "",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text("No Leaf Scanned Yet", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("UPLOAD SCAN"),
                  onPressed: () {
                    state.startLeafScanSimulation();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("CAPTURE LIVE"),
                  onPressed: () {
                    state.startLeafScanSimulation();
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatInterface(FarmerAppState state) {
    return Column(
      children: [
        // Chat History List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.chatMessages.length,
            itemBuilder: (context, idx) {
              final msg = state.chatMessages[idx];
              return Align(
                alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isMe ? MyApp.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isMe ? 16 : 0),
                      bottomRight: Radius.circular(msg.isMe ? 0 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
                    ],
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(
                    msg.text,
                    style: TextStyle(color: msg.isMe ? Colors.white : Colors.black87),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick suggestions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSuggestChip(state, "Is soil moisture 46% good?"),
                _buildSuggestChip(state, "How much water used today?"),
                _buildSuggestChip(state, "Solenoid valve troubleshooting"),
              ],
            ),
          ),
        ),

        // Chat Input Row
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    decoration: const InputDecoration(
                      hintText: "Ask AI Assistant...",
                      border: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (val) => _submitChat(state),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: MyApp.primaryColor),
                  onPressed: () => _submitChat(state),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestChip(FarmerAppState state, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          state.sendChatMessage(text);
          _scrollToBottom();
        },
      ),
    );
  }

  void _submitChat(FarmerAppState state) {
    final text = _chatInputController.text;
    if (text.trim().isNotEmpty) {
      state.sendChatMessage(text);
      _chatInputController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN: NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Alert System Logs")),
      body: state.notifications.isEmpty
          ? const Center(child: Text("No notification logs recorded."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = state.notifications[idx];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.iconColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(item.message, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN: SUPPORT & HELP TICKETS
// ─────────────────────────────────────────────────────────────────────────────

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = "Medium";

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Support Desk")),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: MyApp.primaryColor,
              labelColor: MyApp.primaryColor,
              tabs: [
                Tab(text: "My Tickets"),
                Tab(text: "Contact Support"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTicketsListTab(state),
                  _buildContactTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment),
        label: const Text("New Ticket"),
        onPressed: () {
          _showCreateTicketDialog(context, state);
        },
      ),
    );
  }

  Widget _buildTicketsListTab(FarmerAppState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.tickets.length,
      itemBuilder: (context, idx) {
        final t = state.tickets[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (t.status == "Open" ? Colors.orange : Colors.green).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.status,
                    style: TextStyle(
                      color: t.status == "Open" ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(t.description),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Priority: ${t.priority}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    Text(t.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Need Technical Help?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyApp.primaryColor),
          ),
          const SizedBox(height: 8),
          const Text("Our customer support engineers are available 24/7 for smart controller troubleshooting."),
          const SizedBox(height: 36),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: MyApp.primaryColor),
              title: const Text("Call Helpline"),
              subtitle: const Text("+91 1800 123 4567 (Toll-Free)"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: MyApp.primaryColor),
              title: const Text("Email Support"),
              subtitle: const Text("support@macsoftdrip.com"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context, FarmerAppState state) {
    showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Create Help Ticket"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Subject Title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description details"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Priority: "),
                        const SizedBox(width: 8),
                        ...["Low", "Medium", "High"].map((p) {
                          bool isSel = _selectedPriority == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(p),
                              selected: isSel,
                              selectedColor: MyApp.primaryColor,
                              labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                              onSelected: (selected) {
                                if (selected) {
                                  setStateDialog(() {
                                    _selectedPriority = p;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
                      state.addTicket(_titleController.text, _descController.text, _selectedPriority);
                      _titleController.clear();
                      _descController.clear();
                      Navigator.pop(c);
                    }
                  },
                  child: const Text("Create Ticket"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5: PROFILE & SETTINGS
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = FarmerAppStateScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bio Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MyApp.primaryColor, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 46,
                    backgroundColor: MyApp.primaryColor,
                    child: Icon(Icons.person, size: 54, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("John Doe", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("Farmer User • North Farm Manager", style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Farm Info Card
          const Text("Farm Information", style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.primaryColor)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileRow("Village Location", "Rampur, Punjab"),
                  _buildProfileRow("Drip System Installed", "September 2025"),
                  _buildProfileRow("Total Cultivated Area", "25.0 Acres"),
                  _buildProfileRow("Admin Config Contact", "Admin Team (+91 1800 555 9999)"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Settings Card
          const Text("Application Settings", style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.primaryColor)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Offline Notifications Cache", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    value: true,
                    activeColor: MyApp.primaryColor,
                    onChanged: (v) {},
                  ),
                  SwitchListTile(
                    title: const Text("AI Telemetry Optimization", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    value: true,
                    activeColor: MyApp.primaryColor,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password reset card
          const Text("Security Settings", style: TextStyle(fontWeight: FontWeight.bold, color: MyApp.primaryColor)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _oldPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Current Password"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "New Password"),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      if (_oldPassController.text.isNotEmpty && _newPassController.text.isNotEmpty) {
                        _oldPassController.clear();
                        _newPassController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password updated successfully!")),
                        );
                      }
                    },
                    child: const Text("UPDATE PASSWORD"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              state.logout();
            },
            child: const Text("LOG OUT"),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

// Helper Extension to darken colors
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsv = HSVColor.fromColor(this);
    final hsvDark = hsv.withValue((hsv.value - amount).clamp(0.0, 1.0));
    return hsvDark.toColor();
  }
}

