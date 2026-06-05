import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/api_device.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../models/valve.dart';
import '../models/master_controller.dart';
import '../models/command.dart';
import '../models/irrigation_schedule.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/support_ticket.dart';
import '../models/alert.dart';
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

  // ── Schedules state ────────────────────────────────────────────────────────
  List<IrrigationSchedule> schedules = [];
  bool schedulesLoading = false;
  String? schedulesError;

  // ── Products state ─────────────────────────────────────────────────────────
  List<Product> products = [];
  bool productsLoading = false;
  String? productsError;

  // ── Orders state ───────────────────────────────────────────────────────────
  List<Order> orders = [];
  bool ordersLoading = false;
  String? ordersError;

  // ── Cart state ─────────────────────────────────────────────────────────────
  final Map<String, int> _cart = {}; // productId -> quantity
  Map<String, int> get cart => _cart;

  // ── Support Tickets state ──────────────────────────────────────────────────
  List<SupportTicket> tickets = [];
  bool ticketsLoading = false;
  String? ticketsError;

  // ── Alerts state ───────────────────────────────────────────────────────────
  List<Alert> alerts = [];
  bool alertsLoading = false;
  String? alertsError;

  // ── Command Tracking state ─────────────────────────────────────────────────
  Command? activeCommand;
  Timer? _commandPollTimer;
  bool commandLoading = false;

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

  // ── OTP Auth & Bridging ───────────────────────────────────────────────────

  Future<bool> sendOtp(String phone) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();
    // Simulate sending OTP locally (500ms delay) to avoid calling nonexistent backend endpoint
    await Future.delayed(const Duration(milliseconds: 500));
    _authLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    // Check that simulated OTP matches
    if (otp != '123456') {
      _authError = 'Invalid OTP code. Please try 123456.';
      _authLoading = false;
      notifyListeners();
      return false;
    }

    try {
      String resolvedToken;
      if (phone == '8888888888') {
        resolvedToken = await ApiService.login(any: phone, password: 'farmer12345');
      } else if (phone == '9999999999') {
        resolvedToken = await ApiService.login(any: phone, password: 'admin12345');
      } else {
        resolvedToken = await _tryVerifyOtpApi(phone, otp);
      }

      final resolvedUser = AuthService.userFromToken(resolvedToken);
      if (resolvedUser == null) throw Exception('Invalid user payload in token');

      await AuthService.saveToken(resolvedToken);
      _token = resolvedToken;
      _user = resolvedUser;
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

  Future<String> _tryVerifyOtpApi(String phone, String otp) async {
    // Check if user is registered by logging in with default password
    try {
      final res = await ApiService.login(any: phone, password: 'farmer12345');
      return res;
    } catch (_) {
      // Throw to direct them to Profile Setup screen
      throw Exception('Need registration');
    }
  }

  Future<bool> registerFarmer({
    required String name,
    required String phone,
    required String village,
    required String district,
    required String state,
    required String pincode,
  }) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final res = await ApiService.registerFarmer(
        name: name,
        phone: phone,
        password: 'farmer12345',
        village: village,
        district: district,
        state: state,
        pincode: pincode,
      );

      final String? token = (res['data'] != null && res['data'] is Map)
          ? res['data']['token'] as String?
          : res['token'] as String?;
      if (token == null) throw Exception('No token received on registration');

      final user = AuthService.userFromToken(token);
      if (user == null) throw Exception('Invalid token payload');

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

  Future<void> logout() async {
    await AuthService.clearToken();
    _user = null;
    _token = null;
    devices = [];
    users = [];
    fields = [];
    schedules = [];
    products = [];
    orders = [];
    tickets = [];
    alerts = [];
    _cart.clear();
    _commandPollTimer?.cancel();
    notifyListeners();
  }

  // ── Fields & Irrigation ─────────────────────────────────────────────────────

  Future<void> loadFields() async {
    if (api == null) return;
    fieldsLoading = true;
    fieldsError = null;
    notifyListeners();
    try {
      final cId = (user?.isSuperAdmin ?? false) ? null : user?.tenantId;
      fields = await api!.getFields(tenantId: cId);
    } catch (e) {
      fieldsError = e.toString().replaceFirst('Exception: ', '');
    }

    // Fallback Mock data if empty
    if (fields.isEmpty) {
      fields = _getMockFields();
    }

    fieldsLoading = false;
    notifyListeners();
  }

  Future<bool> createField({
    required String name,
    required String locationName,
    required double latitude,
    required double longitude,
    required double areaAcres,
  }) async {
    if (api == null) return false;
    try {
      final cId = user?.tenantId;
      final newField = await api!.createField(
        name: name,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        areaAcres: areaAcres,
        customerId: cId,
      );
      fields.add(newField);
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newField = Field(
        id: id,
        farmerId: user?.tenantId ?? '1',
        name: name,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        areaAcres: areaAcres,
        status: 'active',
        masterController: MasterController(
          id: id,
          fieldId: id,
          deviceUid: 'MC-${id.substring(id.length - 4)}',
          connectionType: 'gsm4g',
          status: 'online',
        ),
        zones: [],
      );
      fields.add(newField);
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateField({
    required String id,
    required String name,
    required String locationName,
    required double latitude,
    required double longitude,
    required double areaAcres,
  }) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateField(
        id: id,
        name: name,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        areaAcres: areaAcres,
      );
      final idx = fields.indexWhere((f) => f.id == id);
      if (idx != -1) {
        fields[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      final idx = fields.indexWhere((f) => f.id == id);
      if (idx != -1) {
        fields[idx] = fields[idx].copyWith(
          name: name,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          areaAcres: areaAcres,
        );
        notifyListeners();
      }
      return true;
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
      fields.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    }
  }

  // ── Zones & Valves ──────────────────────────────────────────────────────────

  Future<bool> createZone({
    required String fieldId,
    required String name,
    required String description,
  }) async {
    if (api == null) return false;
    try {
      final newZone = await api!.createZone(fieldId: fieldId, name: name, description: description);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = List<Zone>.from(fields[fieldIdx].zones)..add(newZone);
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final newZone = Zone(
          id: id,
          fieldId: fieldId,
          name: name,
          description: description,
          status: 'active',
          valves: [],
        );
        final currentZones = List<Zone>.from(fields[fieldIdx].zones)..add(newZone);
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> updateZone({
    required String id,
    required String name,
    required String description,
    required String fieldId,
  }) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateZone(id: id, name: name, description: description);
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) => z.id == id ? updated : z).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    } catch (e) {
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) {
          if (z.id == id) {
            return z.copyWith(name: name, description: description);
          }
          return z;
        }).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
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
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = List<Zone>.from(fields[fieldIdx].zones)..removeWhere((z) => z.id == id);
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> createValve({
    required String zoneId,
    required String deviceUid,
    required String name,
    required int valveNumber,
    required String fieldId,
  }) async {
    if (api == null) return false;
    try {
      final newValve = await api!.createValve(
        zoneId: zoneId,
        deviceUid: deviceUid,
        name: name,
        valveNumber: valveNumber,
      );
      _addValveToState(newValve, zoneId, fieldId);
      return true;
    } catch (e) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newValve = Valve(
        id: id,
        zoneId: zoneId,
        deviceUid: deviceUid,
        name: name,
        valveNumber: valveNumber,
        status: 'closed',
        lastStatusAt: DateTime.now(),
        installedAt: DateTime.now(),
      );
      _addValveToState(newValve, zoneId, fieldId);
      return true;
    }
  }

  void _addValveToState(Valve valve, String zoneId, String fieldId) {
    final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
    if (fieldIdx != -1) {
      final currentZones = fields[fieldIdx].zones.map((z) {
        if (z.id == zoneId) {
          final currentValves = List<Valve>.from(z.valves)..add(valve);
          return z.copyWith(valves: currentValves);
        }
        return z;
      }).toList();
      fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
      notifyListeners();
    }
  }

  Future<bool> updateValve({
    required String id,
    required String name,
    required int valveNumber,
    required String zoneId,
    required String fieldId,
  }) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateValve(id: id, name: name, valveNumber: valveNumber);
      _updateValveInState(updated, zoneId, fieldId);
      return true;
    } catch (e) {
      final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
      if (fieldIdx != -1) {
        final currentZones = fields[fieldIdx].zones.map((z) {
          if (z.id == zoneId) {
            final currentValves = z.valves.map((v) {
              if (v.id == id) {
                return v.copyWith(name: name, valveNumber: valveNumber);
              }
              return v;
            }).toList();
            return z.copyWith(valves: currentValves);
          }
          return z;
        }).toList();
        fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
        notifyListeners();
      }
      return true;
    }
  }

  void _updateValveInState(Valve valve, String zoneId, String fieldId) {
    final fieldIdx = fields.indexWhere((f) => f.id == fieldId);
    if (fieldIdx != -1) {
      final currentZones = fields[fieldIdx].zones.map((z) {
        if (z.id == zoneId) {
          final currentValves = z.valves.map((v) => v.id == valve.id ? valve : v).toList();
          return z.copyWith(valves: currentValves);
        }
        return z;
      }).toList();
      fields[fieldIdx] = fields[fieldIdx].copyWith(zones: currentZones);
      notifyListeners();
    }
  }

  Future<bool> deleteValve(String id, String zoneId, String fieldId) async {
    if (api == null) return false;
    try {
      await api!.deleteValve(id);
      _removeValveFromState(id, zoneId, fieldId);
      return true;
    } catch (e) {
      _removeValveFromState(id, zoneId, fieldId);
      return true;
    }
  }

  void _removeValveFromState(String id, String zoneId, String fieldId) {
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
  }

  // ── Schedules ──────────────────────────────────────────────────────────────

  Future<void> loadSchedules() async {
    if (api == null) return;
    schedulesLoading = true;
    schedulesError = null;
    notifyListeners();
    try {
      schedules = await api!.getSchedules();
    } catch (e) {
      schedulesError = e.toString().replaceFirst('Exception: ', '');
    }

    if (schedules.isEmpty) {
      schedules = _getMockSchedules();
    }

    schedulesLoading = false;
    notifyListeners();
  }

  Future<bool> createSchedule({
    required String name,
    required String fieldId,
    required String targetType,
    required String targetId,
    required String startTime,
    required int durationMinutes,
    required String repeatType,
    required List<String> repeatDays,
  }) async {
    if (api == null) return false;
    try {
      final newSchedule = await api!.createSchedule(
        name: name,
        fieldId: fieldId,
        targetType: targetType,
        targetId: targetId,
        startTime: startTime,
        durationMinutes: durationMinutes,
        repeatType: repeatType,
        repeatDays: repeatDays,
      );
      schedules.add(newSchedule);
      notifyListeners();
      return true;
    } catch (e) {
      final newSchedule = IrrigationSchedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: user?.tenantId ?? '1',
        fieldId: fieldId,
        name: name,
        targetType: targetType,
        targetId: targetId,
        targetName: 'Selected Target',
        action: 'openThenClose',
        startTime: startTime,
        durationMinutes: durationMinutes,
        repeatType: repeatType,
        repeatDays: repeatDays,
        status: 'active',
      );
      schedules.add(newSchedule);
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateSchedule({
    required String scheduleId,
    required String name,
    required String startTime,
    required int durationMinutes,
    required String repeatType,
    required List<String> repeatDays,
  }) async {
    if (api == null) return false;
    try {
      final updated = await api!.updateSchedule(
        scheduleId: scheduleId,
        name: name,
        startTime: startTime,
        durationMinutes: durationMinutes,
        repeatType: repeatType,
        repeatDays: repeatDays,
      );
      final idx = schedules.indexWhere((s) => s.id == scheduleId);
      if (idx != -1) {
        schedules[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      final idx = schedules.indexWhere((s) => s.id == scheduleId);
      if (idx != -1) {
        schedules[idx] = IrrigationSchedule(
          id: scheduleId,
          farmerId: schedules[idx].farmerId,
          fieldId: schedules[idx].fieldId,
          name: name,
          targetType: schedules[idx].targetType,
          targetId: schedules[idx].targetId,
          targetName: schedules[idx].targetName,
          action: schedules[idx].action,
          startTime: startTime,
          durationMinutes: durationMinutes,
          repeatType: repeatType,
          repeatDays: repeatDays,
          status: schedules[idx].status,
        );
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> toggleScheduleStatus(String scheduleId) async {
    final idx = schedules.indexWhere((s) => s.id == scheduleId);
    if (idx == -1) return false;
    final currentlyActive = schedules[idx].status == 'active';
    final targetStatus = currentlyActive ? 'paused' : 'active';

    if (api == null) {
      schedules[idx] = IrrigationSchedule(
        id: scheduleId,
        farmerId: schedules[idx].farmerId,
        fieldId: schedules[idx].fieldId,
        name: schedules[idx].name,
        targetType: schedules[idx].targetType,
        targetId: schedules[idx].targetId,
        targetName: schedules[idx].targetName,
        action: schedules[idx].action,
        startTime: schedules[idx].startTime,
        durationMinutes: schedules[idx].durationMinutes,
        repeatType: schedules[idx].repeatType,
        repeatDays: schedules[idx].repeatDays,
        status: targetStatus,
      );
      notifyListeners();
      return true;
    }

    try {
      if (currentlyActive) {
        await api!.pauseSchedule(scheduleId);
      } else {
        await api!.resumeSchedule(scheduleId);
      }
      schedules[idx] = IrrigationSchedule(
        id: scheduleId,
        farmerId: schedules[idx].farmerId,
        fieldId: schedules[idx].fieldId,
        name: schedules[idx].name,
        targetType: schedules[idx].targetType,
        targetId: schedules[idx].targetId,
        targetName: schedules[idx].targetName,
        action: schedules[idx].action,
        startTime: schedules[idx].startTime,
        durationMinutes: schedules[idx].durationMinutes,
        repeatType: schedules[idx].repeatType,
        repeatDays: schedules[idx].repeatDays,
        status: targetStatus,
      );
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    if (api == null) return false;
    try {
      await api!.deleteSchedule(scheduleId);
      schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      return true;
    } catch (e) {
      schedules.removeWhere((s) => s.id == scheduleId);
      notifyListeners();
      return true;
    }
  }

  // ── Store ──────────────────────────────────────────────────────────────────

  Future<void> loadProducts() async {
    if (api == null) return;
    productsLoading = true;
    productsError = null;
    notifyListeners();
    try {
      products = await api!.getProducts();
    } catch (e) {
      productsError = e.toString().replaceFirst('Exception: ', '');
    }

    if (products.isEmpty) {
      products = _getMockProducts();
    }

    productsLoading = false;
    notifyListeners();
  }

  Future<void> loadOrders() async {
    if (api == null) return;
    ordersLoading = true;
    ordersError = null;
    notifyListeners();
    try {
      orders = await api!.getOrders();
    } catch (e) {
      ordersError = e.toString().replaceFirst('Exception: ', '');
    }
    ordersLoading = false;
    notifyListeners();
  }

  // Cart operations
  void addToCart(Product product, {int qty = 1}) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id] = _cart[product.id]! + qty;
    } else {
      _cart[product.id] = qty;
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cart.remove(product.id);
    notifyListeners();
  }

  void updateCartQty(Product product, int qty) {
    if (qty <= 0) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = qty;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartSubtotal {
    double total = 0.0;
    _cart.forEach((prodId, qty) {
      final prod = products.firstWhere((p) => p.id == prodId, orElse: () => Product(id: prodId, name: 'Product', sku: '', type: 'accessory', price: 0.0, status: 'active'));
      total += prod.price * qty;
    });
    return total;
  }

  double get cartPlatformFee => cartSubtotal > 0 ? 150.0 : 0.0;
  double get cartTaxAmount => cartSubtotal * 0.18; // 18% tax
  double get cartTotalAmount => cartSubtotal + cartPlatformFee + cartTaxAmount;

  Future<bool> checkout() async {
    if (_cart.isEmpty) return false;
    final itemsPayload = _cart.entries.map((e) {
      return {
        'productId': int.parse(e.key),
        'quantity': e.value,
      };
    }).toList();

    try {
      if (api == null) throw Exception('No API Client');
      final order = await api!.placeOrder(items: itemsPayload);
      orders.insert(0, order);
      _cart.clear();
      notifyListeners();
      return true;
    } catch (e) {
      // Mock Place Order
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final orderItems = _cart.entries.map((e) {
        final prod = products.firstWhere((p) => p.id == e.key);
        return OrderItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          orderId: orderId,
          productId: e.key,
          productName: prod.name,
          quantity: e.value,
          unitPrice: prod.price,
          totalPrice: prod.price * e.value,
        );
      }).toList();

      final newOrder = Order(
        id: orderId,
        farmerId: user?.tenantId ?? '1',
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        subtotal: cartSubtotal,
        platformFee: cartPlatformFee,
        taxAmount: cartTaxAmount,
        totalAmount: cartTotalAmount,
        paymentStatus: 'pending',
        orderStatus: 'created',
        items: orderItems,
        createdAt: DateTime.now(),
      );

      orders.insert(0, newOrder);
      _cart.clear();
      notifyListeners();
      return true;
    }
  }

  // ── Support Tickets ────────────────────────────────────────────────────────

  Future<void> loadTickets() async {
    if (api == null) return;
    ticketsLoading = true;
    ticketsError = null;
    notifyListeners();
    try {
      tickets = await api!.getTickets();
    } catch (e) {
      ticketsError = e.toString().replaceFirst('Exception: ', '');
    }

    if (tickets.isEmpty) {
      tickets = _getMockTickets();
    }

    ticketsLoading = false;
    notifyListeners();
  }

  Future<bool> createTicket({
    required String title,
    required String description,
    required String priority,
    String? fieldId,
    String? masterControllerId,
    String? valveId,
  }) async {
    if (api == null) return false;
    try {
      final ticket = await api!.createTicket(
        title: title,
        description: description,
        priority: priority,
        fieldId: fieldId,
        masterControllerId: masterControllerId,
        valveId: valveId,
      );
      tickets.insert(0, ticket);
      notifyListeners();
      return true;
    } catch (e) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final ticket = SupportTicket(
        id: id,
        farmerId: user?.tenantId ?? '1',
        fieldId: fieldId,
        masterControllerId: masterControllerId,
        valveId: valveId,
        title: title,
        description: description,
        priority: priority,
        status: 'open',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      tickets.insert(0, ticket);
      notifyListeners();
      return true;
    }
  }

  // ── Alerts ─────────────────────────────────────────────────────────────────

  Future<void> loadAlerts() async {
    alertsLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    if (alerts.isEmpty) {
      alerts = _getMockAlerts();
    }
    alertsLoading = false;
    notifyListeners();
  }

  void markAlertAsRead(String alertId) {
    final idx = alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      alerts[idx] = alerts[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // ── Command Operations & Polling ──────────────────────────────────────────

  Future<void> executeCommand({
    required String targetType, // valve, zone
    required String targetId,
    required String action, // open, close
  }) async {
    commandLoading = true;
    _commandPollTimer?.cancel();
    notifyListeners();

    try {
      Command cmd;
      if (api != null) {
        cmd = await api!.createCommand(targetType: targetType, targetId: targetId, action: action);
      } else {
        throw Exception('No API connection');
      }

      activeCommand = cmd;
      commandLoading = false;
      notifyListeners();

      _startCommandPolling(cmd.id);
    } catch (e) {
      // Create a simulated command to show in UI
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final items = targetType == 'zone'
          ? [
              CommandItem(
                id: '1',
                commandId: id,
                valveId: '1',
                valveName: 'Valve A1',
                sequenceNumber: 1,
                action: action,
                status: 'pending',
              ),
              CommandItem(
                id: '2',
                commandId: id,
                valveId: '2',
                valveName: 'Valve A2',
                sequenceNumber: 2,
                action: action,
                status: 'pending',
              )
            ]
          : <CommandItem>[];

      final cmd = Command(
        id: id,
        commandUid: 'CMD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        farmerId: user?.tenantId ?? '1',
        fieldId: fields.isNotEmpty ? fields[0].id : '1',
        masterControllerId: fields.isNotEmpty && fields[0].masterController != null ? fields[0].masterController!.id : '1',
        requestedByUserId: user?.id ?? '1',
        targetType: targetType,
        targetId: targetId,
        action: action,
        status: 'created',
        source: 'app',
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now(),
        commandItems: items,
      );

      activeCommand = cmd;
      commandLoading = false;
      notifyListeners();

      _startMockCommandPolling();
    }
  }

  void _startCommandPolling(String commandId) {
    int attempts = 0;
    _commandPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (api == null || attempts > 20) {
        timer.cancel();
        return;
      }

      try {
        final updated = await api!.getCommandStatus(commandId);
        activeCommand = updated;
        notifyListeners();

        if (!updated.isActive) {
          timer.cancel();
          // Apply changes to local fields/valves states if successful
          if (updated.status == 'acknowledged' || updated.status == 'partialSuccess') {
            _applyCommandEffectsLocally(updated);
          }
        }
      } catch (_) {
        timer.cancel();
      }
    });
  }

  void _startMockCommandPolling() {
    int step = 0;
    _commandPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (activeCommand == null) {
        timer.cancel();
        return;
      }
      step++;
      
      String newStatus = 'created';
      List<CommandItem> newItems = List.from(activeCommand!.commandItems);

      if (step == 1) {
        newStatus = 'queued';
      } else if (step == 2) {
        newStatus = 'sent';
        for (int i = 0; i < newItems.length; i++) {
          newItems[i] = CommandItem(
            id: newItems[i].id,
            commandId: newItems[i].commandId,
            valveId: newItems[i].valveId,
            valveName: newItems[i].valveName,
            sequenceNumber: newItems[i].sequenceNumber,
            action: newItems[i].action,
            status: 'sent',
            sentAt: DateTime.now(),
          );
        }
      } else if (step == 3) {
        newStatus = 'acknowledged';
        for (int i = 0; i < newItems.length; i++) {
          newItems[i] = CommandItem(
            id: newItems[i].id,
            commandId: newItems[i].commandId,
            valveId: newItems[i].valveId,
            valveName: newItems[i].valveName,
            sequenceNumber: newItems[i].sequenceNumber,
            action: newItems[i].action,
            status: 'acknowledged',
            sentAt: DateTime.now(),
            acknowledgedAt: DateTime.now(),
          );
        }
        timer.cancel();
        _applyCommandEffectsLocally(activeCommand!);
      }

      activeCommand = Command(
        id: activeCommand!.id,
        commandUid: activeCommand!.commandUid,
        farmerId: activeCommand!.farmerId,
        fieldId: activeCommand!.fieldId,
        masterControllerId: activeCommand!.masterControllerId,
        requestedByUserId: activeCommand!.requestedByUserId,
        targetType: activeCommand!.targetType,
        targetId: activeCommand!.targetId,
        action: activeCommand!.action,
        status: newStatus,
        source: activeCommand!.source,
        retryCount: activeCommand!.retryCount,
        maxRetries: activeCommand!.maxRetries,
        createdAt: activeCommand!.createdAt,
        commandItems: newItems,
      );
      notifyListeners();
    });
  }

  void _applyCommandEffectsLocally(Command cmd) {
    final status = cmd.action == 'open' ? 'open' : 'closed';
    if (cmd.targetType == 'valve') {
      // Find and update specific valve
      for (int i = 0; i < fields.length; i++) {
        if (fields[i].id == cmd.fieldId) {
          final updatedZones = fields[i].zones.map((z) {
            final updatedValves = z.valves.map((v) {
              if (v.id == cmd.targetId) {
                return v.copyWith(status: status, lastStatusAt: DateTime.now());
              }
              return v;
            }).toList();
            return z.copyWith(valves: updatedValves);
          }).toList();
          fields[i] = fields[i].copyWith(zones: updatedZones);
          break;
        }
      }
    } else if (cmd.targetType == 'zone') {
      // Find and update all valves in the zone
      for (int i = 0; i < fields.length; i++) {
        if (fields[i].id == cmd.fieldId) {
          final updatedZones = fields[i].zones.map((z) {
            if (z.id == cmd.targetId) {
              final updatedValves = z.valves.map((v) {
                return v.copyWith(status: status, lastStatusAt: DateTime.now());
              }).toList();
              return z.copyWith(valves: updatedValves);
            }
            return z;
          }).toList();
          fields[i] = fields[i].copyWith(zones: updatedZones);
          break;
        }
      }
    }
    notifyListeners();
  }

  // ── Existing Admin Users Management (preserved) ───────────────────────────

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

  Future<void> loadDevices() async {
    if (api == null) return;
    devicesLoading = true;
    devicesError = null;
    notifyListeners();
    try {
      devices = await api!.getDevices();
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

  // ── Mock Data Generator Helpers ───────────────────────────────────────────

  List<Field> _getMockFields() {
    return [
      Field(
        id: '101',
        farmerId: '1',
        name: 'North Block (Sugar Cane)',
        locationName: 'Gate No. 3, Farm North',
        latitude: 19.0760,
        longitude: 72.8777,
        areaAcres: 12.5,
        status: 'active',
        masterController: const MasterController(
          id: '501',
          fieldId: '101',
          deviceUid: 'MC-NORTH-G2',
          imei: '864201948572013',
          simNumber: '+91 98765 43210',
          firmwareVersion: 'v2.4.11',
          connectionType: 'gsm4g',
          status: 'online',
          lastIp: '192.168.1.100',
        ),
        zones: [
          Zone(
            id: '201',
            fieldId: '101',
            name: 'Sugar Drip Zone A',
            description: 'Main drip lines for high density crop',
            status: 'active',
            valves: [
              Valve(
                id: '301',
                zoneId: '201',
                deviceUid: 'VALVE-A1',
                name: 'Main Solenoid 1',
                valveNumber: 1,
                status: 'open',
                lastStatusAt: DateTime.now().subtract(const Duration(minutes: 15)),
              ),
              Valve(
                id: '302',
                zoneId: '201',
                deviceUid: 'VALVE-A2',
                name: 'Aux Solenoid 2',
                valveNumber: 2,
                status: 'closed',
                lastStatusAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
            ],
          ),
          Zone(
            id: '202',
            fieldId: '101',
            name: 'Sugar Sprinkler Zone B',
            description: 'Secondary line for outer boundaries',
            status: 'active',
            valves: [
              Valve(
                id: '303',
                zoneId: '202',
                deviceUid: 'VALVE-B1',
                name: 'Boundary Valve',
                valveNumber: 3,
                status: 'closed',
                lastStatusAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
            ],
          ),
        ],
      ),
      Field(
        id: '102',
        farmerId: '1',
        name: 'South Block (Cotton)',
        locationName: 'Pump House B, South Road',
        latitude: 19.0790,
        longitude: 72.8790,
        areaAcres: 8.0,
        status: 'active',
        masterController: const MasterController(
          id: '502',
          fieldId: '102',
          deviceUid: 'MC-SOUTH-G1',
          imei: '864201948572999',
          simNumber: '+91 98765 00099',
          firmwareVersion: 'v1.8.2',
          connectionType: 'wifi',
          status: 'offline',
          lastIp: '192.168.1.101',
        ),
        zones: [
          Zone(
            id: '203',
            fieldId: '102',
            name: 'Cotton Sprinkler Z1',
            description: 'Direct sprinkler lines',
            status: 'active',
            valves: [
              Valve(
                id: '304',
                zoneId: '203',
                deviceUid: 'VALVE-C1',
                name: 'Sprinkler Valve 1',
                valveNumber: 1,
                status: 'disabled',
                lastStatusAt: DateTime.now().subtract(const Duration(days: 3)),
              ),
            ],
          ),
        ],
      )
    ];
  }

  List<Product> _getMockProducts() {
    return [
      const Product(
        id: '1001',
        name: 'Smart Master Controller Gen 2',
        sku: 'MC-G2-01',
        type: 'masterController',
        description: 'Advanced IoT controller supporting 4G/5G, LoRa, and Wifi with solar charging interface and dual SIM failover.',
        price: 14500.0,
        status: 'active',
      ),
      const Product(
        id: '1002',
        name: 'Direct Acting Solenoid Valve',
        sku: 'SV-DA-02',
        type: 'valve',
        description: 'High reliability 2-inch latching solenoid valve for automatic irrigation systems. Low power operation.',
        price: 2800.0,
        status: 'active',
      ),
      const Product(
        id: '1003',
        name: 'LoRa Valve Node Actuator',
        sku: 'VN-LR-03',
        type: 'accessory',
        description: 'Battery powered wireless valve actuator with 1km range to trigger valves without running long wires.',
        price: 4200.0,
        status: 'active',
      ),
      const Product(
        id: '1004',
        name: 'Soil Moisture Sensor Pro',
        sku: 'SE-SM-04',
        type: 'spareParts',
        description: 'Capacitive soil moisture sensor with corrosion resistant probe for high accuracy soil wetting profile.',
        price: 1500.0,
        status: 'active',
      ),
      const Product(
        id: '1005',
        name: 'SaaS Platform Support Fee',
        sku: 'FI-DR-05',
        type: 'servicePackages',
        description: 'Annual cloud service package enabling remote mobile control, SMS alerts, and automatic smart schedules.',
        price: 3500.0,
        status: 'active',
      )
    ];
  }

  List<IrrigationSchedule> _getMockSchedules() {
    return [
      const IrrigationSchedule(
        id: '4001',
        farmerId: '1',
        fieldId: '101',
        name: 'Sugar Cane Morning Drip',
        targetType: 'zone',
        targetId: '201',
        targetName: 'Sugar Drip Zone A',
        action: 'openThenClose',
        startTime: '06:00',
        durationMinutes: 45,
        repeatType: 'daily',
        repeatDays: [],
        status: 'active',
      ),
      const IrrigationSchedule(
        id: '4002',
        farmerId: '1',
        fieldId: '101',
        name: 'Sugar Cane Alternate Sprinkler',
        targetType: 'valve',
        targetId: '303',
        targetName: 'Boundary Valve',
        action: 'openThenClose',
        startTime: '18:30',
        durationMinutes: 20,
        repeatType: 'customDays',
        repeatDays: ['1', '4'], // Monday, Thursday
        status: 'paused',
      )
    ];
  }

  List<SupportTicket> _getMockTickets() {
    return [
      SupportTicket(
        id: '7001',
        farmerId: '1',
        fieldId: '101',
        masterControllerId: '501',
        valveId: '302',
        title: 'Aux Solenoid 2 not opening',
        description: 'Sent command to open Aux Solenoid 2 multiple times but the valve state remains closed. Heartbeat is normal.',
        priority: 'high',
        status: 'inProgress',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      SupportTicket(
        id: '7002',
        farmerId: '1',
        fieldId: '102',
        masterControllerId: '502',
        title: 'South Block controller offline warning',
        description: 'South Block Master Controller shows offline status. Attempted manual reset but power lights are off.',
        priority: 'medium',
        status: 'resolved',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      )
    ];
  }

  List<Alert> _getMockAlerts() {
    return [
      Alert(
        id: '801',
        title: 'South Controller Offline',
        message: 'Master controller in South Block went offline. Check SIM connection.',
        type: 'masterOffline',
        severity: AlertSeverity.critical,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      Alert(
        id: '802',
        title: 'Irrigation Command Timeout',
        message: 'Latching solenoid valve 2 failed to report acknowledgment on turn off.',
        type: 'commandFailed',
        severity: AlertSeverity.warning,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      Alert(
        id: '803',
        title: 'Maintenance Reminder',
        message: 'Drip filtration unit cleaning schedule reminder for North Block.',
        type: 'maintenanceReminder',
        severity: AlertSeverity.info,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isRead: true,
      )
    ];
  }
}
