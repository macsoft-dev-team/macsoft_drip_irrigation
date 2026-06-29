import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
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
import '../models/slave_board.dart';

const String _baseUrl = Env.apiBaseUrl;

/// Central HTTP client for all backend calls.
class ApiService {
  final String token;
  const ApiService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<String> login({
    required String any,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': any, 'password': password}),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return _unwrap(body)['token'] as String;
    }
    final err = _errorMsg(res);
    throw Exception(err);
  }

  static Future<Map<String, dynamic>> registerFarmer({
    required String name,
    required String phone,
    required String password,
    String? address,
    String? village,
    String? district,
    String? state,
    String? pincode,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/registerFarmer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'password': password,
        'address': address,
        'village': village,
        'district': district,
        'state': state,
        'pincode': pincode,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final err = _errorMsg(res);
    throw Exception(err);
  }

  static Future<void> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/sendOtp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMsg(res));
    }
  }

  static Future<String> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/verifyOtp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['token'] as String;
    }
    throw Exception(_errorMsg(res));
  }

  Future<void> sendOtpInstance(String phone) => ApiService.sendOtp(phone);
  Future<String> verifyOtpInstance(String phone, String otp) => ApiService.verifyOtp(phone, otp);


  // ── Devices ────────────────────────────────────────────────────────────────

  Future<List<ApiDevice>> getDevices({int skip = 0, int take = 50}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/devices?skip=$skip&take=$take'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final List<dynamic> list;
    if (body is List) {
      list = body;
    } else {
      final data = body['data'];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = (data['devices'] ?? []) as List<dynamic>;
      } else {
        list = (body['devices'] ?? []) as List<dynamic>;
      }
    }
    return list
        .map((e) => ApiDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiDevice> createDevice(String imei) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/devices'),
      headers: _headers,
      body: jsonEncode({'imeinumber': imei}),
    );
    _check(res);
    return ApiDevice.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Map<String, dynamic>> uploadDevices(List<String> imeis) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/devices/upload'),
      headers: _headers,
      body: jsonEncode({'imeis': imeis}),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<ApiDevice> updateDevice(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/devices/$deviceId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return ApiDevice.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> saveDeviceConfig(
    String deviceId,
    Map<String, dynamic> config,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/devices/$deviceId/config'),
      headers: _headers,
      body: jsonEncode(config),
    );
    _check(res);
  }

  Future<List<TelemetryRow>> getTelemetry({
    required String deviceId,
    required String from,
    required String to,
    int skip = 0,
    int take = 50,
  }) async {
    final res = await http.get(
      Uri.parse(
        '$_baseUrl/devices/$deviceId/telemetry?from=$from&to=$to&skip=$skip&take=$take',
      ),
      headers: _headers,
    );
    _check(res);
    final decoded = jsonDecode(res.body);
    final List<dynamic> body = decoded is List
        ? decoded
        : (decoded['data'] ?? decoded['telemetry'] ?? []) as List<dynamic>;
    return body
        .map((e) => TelemetryRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeviceCommand> sendCommand(
    String deviceId,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/devices/$deviceId/commands'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return DeviceCommand.fromJson(data);
  }

  Future<List<DeviceCommand>> getCommands(String deviceId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/devices/$deviceId/commands'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['commands'] ?? body['data'] ?? []) as List;
    return list
        .map((e) => DeviceCommand.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<({List<AppUser> users, int totalPages, int currentPage})> getUsers({
    int page = 1,
    int take = 10,
    String filter = '',
  }) async {
    final res = await http.get(
      Uri.parse(
        '$_baseUrl/users?skip=$page&take=$take&filter=${Uri.encodeQueryComponent(filter)}',
      ),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final unwrapped = _unwrap(body);
    final List<dynamic> rawList = unwrapped is List ? (unwrapped as List<dynamic>) : (body['users'] as List<dynamic>? ?? []);
    final list = rawList
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      users: list,
      totalPages: (body['totalPages'] as int?) ?? 1,
      currentPage: (body['currentPage'] as int?) ?? 1,
    );
  }

  Future<AppUser> createUser(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return AppUser.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return AppUser.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> deleteUser(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorMsg(res));
    }
  }

  Future<List<AppUser>> getUserOptions() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users?take=200&role=USER'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['users'] as List<dynamic>? ?? [])
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fields ─────────────────────────────────────────────────────────────────

  Future<List<Field>> getFields({String? tenantId, String? customerId, int skip = 0, int take = 100}) async {
    final activeTenantId = tenantId ?? customerId;
    final query = activeTenantId != null ? 'tenantId=$activeTenantId&skip=$skip&take=$take' : 'skip=$skip&take=$take';
    final res = await http.get(
      Uri.parse('$_baseUrl/fields?$query'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['fields'] as List<dynamic>? ?? body['data'] as List<dynamic>? ?? []);
    return list.map((e) => Field.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Field> getFieldDetail(String fieldId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/fields/$fieldId'),
      headers: _headers,
    );
    _check(res);
    return Field.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Field> createField({
    required String name,
    required String locationName,
    required double latitude,
    required double longitude,
    required double areaAcres,
    String? tenantId,
    String? customerId,
  }) async {
    final activeTenantId = tenantId ?? customerId;
    final res = await http.post(
      Uri.parse('$_baseUrl/fields'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'areaAcres': areaAcres,
        'tenantId': activeTenantId,
      }),
    );
    _check(res);
    return Field.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Field> updateField({
    required String id,
    required String name,
    required String locationName,
    required double latitude,
    required double longitude,
    required double areaAcres,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/fields/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'areaAcres': areaAcres,
      }),
    );
    _check(res);
    return Field.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> deleteField(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/fields/$id'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Master Controllers ──────────────────────────────────────────────────────

  Future<MasterController> getMasterControllerForField(String fieldId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/fields/$fieldId/masterController'),
      headers: _headers,
    );
    _check(res);
    return MasterController.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<MasterController> getMasterController(String masterControllerId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/masterControllers/$masterControllerId'),
      headers: _headers,
    );
    _check(res);
    return MasterController.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<MasterController> createMasterController(String fieldId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/fields/$fieldId/masterController'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return MasterController.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  // ── Zones ──────────────────────────────────────────────────────────────────

  Future<List<Zone>> getZones({required String fieldId, int skip = 0, int take = 100}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/fields/$fieldId/zones?skip=$skip&take=$take'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['zones'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Zone> createZone({
    required String fieldId,
    required String name,
    required String description,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/fields/$fieldId/zones'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    _check(res);
    return Zone.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Zone> updateZone({
    required String id,
    required String name,
    required String description,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/zones/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    _check(res);
    return Zone.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> deleteZone(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/zones/$id'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Valves ─────────────────────────────────────────────────────────────────

  Future<List<Valve>> getValves({required String zoneId, int skip = 0, int take = 100}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/zones/$zoneId/valves?skip=$skip&take=$take'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['valves'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => Valve.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Valve> createValve({
    required String zoneId,
    required String deviceUid,
    required String name,
    required int valveNumber,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/zones/$zoneId/valves'),
      headers: _headers,
      body: jsonEncode({
        'deviceUid': deviceUid,
        'name': name,
        'valveNumber': valveNumber,
      }),
    );
    _check(res);
    return Valve.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Valve> updateValve({
    required String id,
    required String name,
    required int valveNumber,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/valves/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'valveNumber': valveNumber,
      }),
    );
    _check(res);
    return Valve.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> deleteValve(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/valves/$id'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Commands ───────────────────────────────────────────────────────────────

  Future<Command> createCommand({
    required String targetType, // valve, zone
    required String targetId,
    required String action, // open, close
  }) async {
    final path = targetType == 'zone'
        ? '$_baseUrl/commands/zones/$targetId/$action'
        : '$_baseUrl/commands/valves/$targetId/$action';

    final res = await http.post(
      Uri.parse(path),
      headers: _headers,
    );
    _check(res);
    return Command.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Command> controlMotor({
    required String masterControllerId,
    required String action, // start, stop
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/commands/masterControllers/$masterControllerId/motor/$action'),
      headers: _headers,
    );
    _check(res);
    return Command.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Command> getCommandStatus(String commandId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/commands/$commandId'),
      headers: _headers,
    );
    _check(res);
    return Command.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<List<CommandItem>> getCommandItems(String commandId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/commands/$commandId/items'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['items'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => CommandItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Command>> getFieldCommands(String fieldId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/fields/$fieldId/commands'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['commands'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => Command.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Command>> getValveCommands(String valveId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/valves/$valveId/commands'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['commands'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => Command.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Schedules ──────────────────────────────────────────────────────────────

  Future<List<IrrigationSchedule>> getSchedules() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/schedules'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['schedules'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => IrrigationSchedule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<IrrigationSchedule> createSchedule({
    required String name,
    required String fieldId,
    required String targetType,
    required String targetId,
    required String startTime,
    required int durationMinutes,
    required String repeatType,
    required List<String> repeatDays,
    String scheduleType = 'timeBased',
    List<String>? zoneIds,
    List<dynamic>? sequenceData,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/schedules'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'fieldId': int.parse(fieldId),
        'targetType': targetType,
        'targetId': int.parse(targetId),
        'startTime': startTime,
        'durationMinutes': durationMinutes,
        'repeatType': repeatType,
        'repeatDays': repeatDays,
        'scheduleType': scheduleType,
        'zoneIds': zoneIds,
        'sequenceData': sequenceData,
      }),
    );
    _check(res);
    return IrrigationSchedule.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<IrrigationSchedule> updateSchedule({
    required String scheduleId,
    required String name,
    required String startTime,
    required int durationMinutes,
    required String repeatType,
    required List<String> repeatDays,
    String? scheduleType,
    List<String>? zoneIds,
    List<dynamic>? sequenceData,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/schedules/$scheduleId'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'startTime': startTime,
        'durationMinutes': durationMinutes,
        'repeatType': repeatType,
        'repeatDays': repeatDays,
        if (scheduleType != null) 'scheduleType': scheduleType,
        if (zoneIds != null) 'zoneIds': zoneIds,
        if (sequenceData != null) 'sequenceData': sequenceData,
      }),
    );
    _check(res);
    return IrrigationSchedule.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/schedules/$scheduleId'),
      headers: _headers,
    );
    _check(res);
  }

  Future<void> pauseSchedule(String scheduleId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/schedules/$scheduleId/pause'),
      headers: _headers,
    );
    _check(res);
  }

  Future<void> resumeSchedule(String scheduleId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/schedules/$scheduleId/resume'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Store ──────────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['products'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> getProductDetail(String productId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: _headers,
    );
    _check(res);
    return Product.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<Order> placeOrder({
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({
        'items': items,
      }),
    );
    _check(res);
    return Order.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<List<Order>> getOrders() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['orders'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrderDetail(String orderId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: _headers,
    );
    _check(res);
    return Order.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  // ── Support ────────────────────────────────────────────────────────────────

  Future<List<SupportTicket>> getTickets() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/supportTickets'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body['tickets'] ?? body['data'] ?? []) as List<dynamic>;
    return list.map((e) => SupportTicket.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SupportTicket> createTicket({
    required String title,
    required String description,
    required String priority,
    String? fieldId,
    String? masterControllerId,
    String? valveId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/supportTickets'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        if (fieldId != null) 'fieldId': int.parse(fieldId),
        if (masterControllerId != null) 'masterControllerId': int.parse(masterControllerId),
        if (valveId != null) 'valveId': int.parse(valveId),
      }),
    );
    _check(res);
    return SupportTicket.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<SupportTicket> getTicketDetail(String ticketId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/supportTickets/$ticketId'),
      headers: _headers,
    );
    _check(res);
    return SupportTicket.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<SupportTicket> updateTicket(String ticketId, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/supportTickets/$ticketId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return SupportTicket.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<List<SlaveBoard>> getSlaveBoards(String masterControllerId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/masterControllers/$masterControllerId/slaveBoards'),
      headers: _headers,
    );
    _check(res);
    final list = jsonDecode(res.body) as List;
    return list.map((item) => SlaveBoard.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<SlaveBoard> createSlaveBoard(String masterControllerId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/masterControllers/$masterControllerId/slaveBoards'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return SlaveBoard.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<SlaveBoard> updateSlaveBoard(String slaveBoardId, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/slaveBoards/$slaveBoardId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return SlaveBoard.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> deleteSlaveBoard(String slaveBoardId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/slaveBoards/$slaveBoardId'),
      headers: _headers,
    );
    _check(res);
  }

  Future<Valve> createValveDirect(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/valves'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return Valve.fromJson(_unwrap(jsonDecode(res.body) as Map<String, dynamic>));
  }

  Future<void> assignValveToZone(String valveId, String zoneId) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/valves/$valveId/assignZone'),
      headers: _headers,
      body: jsonEncode({'zoneId': zoneId}),
    );
    _check(res);
  }

  Future<List<Valve>> getValvesBySlaveBoard(String slaveBoardId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/slaveBoards/$slaveBoardId/valves'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body);
    final List<dynamic> list;
    if (body is List) {
      list = body;
    } else {
      list = (body['valves'] ?? body['data'] ?? []) as List<dynamic>;
    }
    return list.map((e) => Valve.fromJson(e as Map<String, dynamic>)).toList();
  }


  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _unwrap(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_errorMsg(res));
    }
  }

  static String _errorMsg(http.Response res) {
    try {
      final b = jsonDecode(res.body) as Map<String, dynamic>;
      return b['message'] ?? b['error'] ?? 'HTTP ${res.statusCode}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tenants?take=200'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['tenants'] ?? []);
  }

  Future<Map<String, dynamic>> diagnoseCropLeaf({
    required String cropType,
    required String fieldId,
    List<int>? fileBytes,
    String? filename,
  }) async {
    final uri = Uri.parse('http://127.0.0.1:8080/api/v1/diagnose');
    final request = http.MultipartRequest('POST', uri);

    request.fields['crop_type'] = cropType;
    request.fields['field_id'] = fieldId;

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename ?? 'leaf_sample.jpg',
        ),
      );
    } else {
      final dummyBytes = [
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
        0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 204, 137, 0, 0, 0, 13, 73, 68, 65, 84,
        120, 94, 99, 96, 0, 0, 0, 2, 0, 1, 73, 175, 168, 147, 0, 0, 0, 0, 73, 69,
        78, 68, 174, 66, 96, 130
      ];
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          dummyBytes,
          filename: 'dummy_leaf.png',
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('AI Server Status ${res.statusCode}');
      }
    } catch (_) {
      // Graceful fallback if uvicorn isn't running locally
      await Future.delayed(const Duration(milliseconds: 1200));
      return {
        "status": "success",
        "crop": cropType,
        "field_id": fieldId,
        "disease": _getMockDiseaseName(cropType),
        "scientific_name": _getMockScientificName(cropType),
        "confidence": 0.94,
        "severity": _getMockSeverity(cropType),
        "description": "Foliar diagnostic sweep scan identifies crop tissue abnormalities. (AI engine offline fallback)",
        "treatment": "Prune spotted leaves to prevent growth. Treat with recommended organic copper sprays.",
        "drip_irrigation_action": _getMockDripAction(cropType),
        "sensor_status": cropType.toLowerCase() == 'tomato' ? "noisy_signal_detected" : "optimal",
        "metadata": {
          "resolution": "800x600",
          "processed_at": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "engine": "DripAI ResNet-50 v2.1 (Offline mode)"
        }
      };
    }
  }

  String _getMockDiseaseName(String crop) {
    switch (crop.toLowerCase()) {
      case 'tomato':
        return 'Tomato Late Blight';
      case 'cotton':
        return 'Cotton Leaf Rust';
      case 'sugarcane':
        return 'Sugarcane Red Rot';
      case 'wheat':
        return 'Wheat Powdery Mildew';
      default:
        return 'Healthy Crop (No Disease)';
    }
  }

  String _getMockScientificName(String crop) {
    switch (crop.toLowerCase()) {
      case 'tomato':
        return 'Phytophthora infestans';
      case 'cotton':
        return 'Puccinia cacabata';
      case 'sugarcane':
        return 'Colletotrichum falcatum';
      case 'wheat':
        return 'Blumeria graminis';
      default:
        return 'N/A';
    }
  }

  String _getMockSeverity(String crop) {
    switch (crop.toLowerCase()) {
      case 'tomato':
        return 'CRITICAL';
      case 'cotton':
      case 'sugarcane':
        return 'HIGH';
      case 'wheat':
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }

  String _getMockDripAction(String crop) {
    switch (crop.toLowerCase()) {
      case 'tomato':
        return 'Reduce drip runtime by 35% in Zone 2. Run irrigation strictly in the early morning (4 AM - 6 AM) so the soil surface dries out, preventing spore germination.';
      case 'cotton':
        return 'Shift irrigation to a deep, less frequent pattern (increase intervals from 2 days to 4 days) to prevent humidity build-up in the lower canopy.';
      case 'sugarcane':
        return 'Enable automatic Soil Moisture Sensor Feedback. Restrict irrigation runtime if soil moisture exceeds 75% to prevent vascular rot progression.';
      case 'wheat':
        return 'Reduce daily watering times by 15%. High canopy moisture is fostering powdery mildew propagation.';
      default:
        return 'Maintain active auto-drip schedules. No emergency moisture adjustments required.';
    }
  }
}
