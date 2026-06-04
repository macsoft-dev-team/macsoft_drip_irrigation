import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/api_device.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../models/valve.dart';
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

  // ── Fields & Irrigation state ──────────────────────────────────────────────
  List<Field> fields = [];
  bool fieldsLoading = false;
  String? fieldsError;

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

  // ── Fields & Irrigation ─────────────────────────────────────────────────────

  Future<void> loadFields() async {
    if (api == null) return;
    fieldsLoading = true;
    fieldsError = null;
    notifyListeners();
    try {
      final cId = (user?.role == UserRole.superadmin) ? null : user?.customerId;
      fields = await api!.getFields(customerId: cId);
    } catch (e) {
      fieldsError = e.toString().replaceFirst('Exception: ', '');
    }
    fieldsLoading = false;
    notifyListeners();
  }

  Future<bool> createField(String name, String customerId) async {
    if (api == null) return false;
    try {
      final newField = await api!.createField(name: name, customerId: customerId);
      fields.add(newField);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateField(String id, String name) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateField(id: id, name: name);
      final idx = fields.indexWhere((f) => f.id == id);
      if (idx != -1) {
        fields[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteField(String id) async {
    if (api == null) return false;
    try {
      await api!.deleteField(id);
      fields.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createZone(String name, String fieldId) async {
    if (api == null) return false;
    try {
      final newZone = await api!.createZone(name: name, fieldId: fieldId);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = List<Zone>.from(fields[fieldIdx].zones)..add(newZone);
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateZone(String id, String name, String fieldId) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateZone(id: id, name: name);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) => z.id == id ? updated : z).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteZone(String id, String fieldId) async {
    if (api == null) return false;
    try {
      await api!.deleteZone(id);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = List<Zone>.from(fields[fieldIdx].zones)..removeWhere((z) => z.id == id);
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createValve(String name, String zoneId, String fieldId) async {
    if (api == null) return false;
    try {
      final newValve = await api!.createValve(name: name, zoneId: zoneId);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) {
          if (z.id == zoneId) {
            final currentValves = List<Valve>.from(z.valves)..add(newValve);
            return z.copyWith(valves: currentValves);
          }
          return z;
        }).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateValve(String id, String name, String zoneId, String fieldId) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateValve(id: id, name: name);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) {
          if (z.id == zoneId) {
            final currentValves = z.valves.map((v) => v.id == id ? updated : v).toList();
            return z.copyWith(valves: currentValves);
          }
          return z;
        }).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteValve(String id, String zoneId, String fieldId) async {
    if (api == null) return false;
    try {
      await api!.deleteValve(id);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) {
          if (z.id == zoneId) {
            final currentValves = List<Valve>.from(z.valves)..removeWhere((v) => v.id == id);
            return z.copyWith(valves: currentValves);
          }
          return z;
        }).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
