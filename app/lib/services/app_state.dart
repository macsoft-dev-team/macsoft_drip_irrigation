import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/api_device.dart';
import 'auth_service.dart';
import 'api_service.dart';

/// Central application state accessed via Provider.
class AppState extends ChangeNotifier {
  // ── Auth state ─────────────────────────────────────────────────────────────
  AppUser? _user;
  String? _token;
  bool _authLoading = false;
  String? _authError;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;
  bool get authLoading => _authLoading;
  String? get authError => _authError;

  ApiService? get api => _token != null ? ApiService(token: _token!) : null;

  // ── Device state ───────────────────────────────────────────────────────────
  List<ApiDevice> devices = [];
  bool devicesLoading = false;
  String? devicesError;

  // ── Users state ────────────────────────────────────────────────────────────
  List<AppUser> users = [];
  int usersTotalPages = 1;
  int usersCurrentPage = 1;
  bool usersLoading = false;
  String? usersError;

  // ── App boot: restore saved session ───────────────────────────────────────

  Future<void> restoreSession() async {
    final session = await AuthService.restoreSession();
    if (session != null) {
      _user = session.user;
      _token = session.token;
      notifyListeners();
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login({required String any, required String password}) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final token = await ApiService.login(any: any, password: password);
      final user = AuthService.userFromToken(token);
      if (user == null) throw Exception('Invalid token received');

      await AuthService.saveToken(token);
      _token = token;
      _user = user;
      _authLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _authError = e.toString().replaceFirst('Exception: ', '');
      _authLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.clearToken();
    _user = null;
    _token = null;
    devices = [];
    users = [];
    notifyListeners();
  }

  // ── Devices ────────────────────────────────────────────────────────────────

  Future<void> loadDevices() async {
    if (api == null) return;
    devicesLoading = true;
    devicesError = null;
    notifyListeners();
    try {
      devices = await api!.getDevices(take: 100);
    } catch (e) {
      devicesError = e.toString().replaceFirst('Exception: ', '');
    }
    devicesLoading = false;
    notifyListeners();
  }

  void updateDeviceLive(String deviceId, TelemetryRow row) {
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx == -1) return;
    devices[idx] = devices[idx].copyWith(isActive: true, telemetryLogs: [row]);
    notifyListeners();
  }

  void updateDeviceConfig(String deviceId, Map<String, dynamic> config) {
    final idx = devices.indexWhere((d) => d.id == deviceId);
    if (idx == -1) return;
    devices[idx] = devices[idx].copyWith(config: config);
    notifyListeners();
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> loadUsers({int page = 1, String filter = ''}) async {
    if (api == null) return;
    usersLoading = true;
    usersError = null;
    notifyListeners();
    try {
      final result = await api!.getUsers(page: page, filter: filter);
      users = result.users;
      usersTotalPages = result.totalPages;
      usersCurrentPage = result.currentPage;
    } catch (e) {
      usersError = e.toString().replaceFirst('Exception: ', '');
    }
    usersLoading = false;
    notifyListeners();
  }
}
