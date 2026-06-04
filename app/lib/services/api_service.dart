import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/app_user.dart';
import '../models/api_device.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../models/valve.dart';

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
      body: jsonEncode({'any': any, 'password': password}),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['token'] as String;
    }
    final err = _errorMsg(res);
    throw Exception(err);
  }

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
      // Controller wraps service result: { data: { devices: [...], totalCount } }
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
    return ApiDevice.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
    return ApiDevice.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
    final list = (body['users'] as List<dynamic>? ?? [])
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
    return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/users/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    _check(res);
    return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  // ── Convenience: fetch USER-role users for device assignment ──────────────
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
  Future<List<Field>> getFields({String? customerId, int skip = 0, int take = 100}) async {
    final query = customerId != null ? 'customerId=$customerId&skip=$skip&take=$take' : 'skip=$skip&take=$take';
    final res = await http.get(
      Uri.parse('$_baseUrl/fields?$query'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['fields'] as List<dynamic>? ?? []);
    return list.map((e) => Field.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Field> createField({required String name, required String customerId}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/fields'),
      headers: _headers,
      body: jsonEncode({'name': name, 'customerId': customerId}),
    );
    _check(res);
    return Field.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Field> updateField({required String id, required String name}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/fields/$id'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    _check(res);
    return Field.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteField(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/fields/$id'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Zones ──────────────────────────────────────────────────────────────────
  Future<List<Zone>> getZones({String? fieldId, int skip = 0, int take = 100}) async {
    final query = fieldId != null ? 'fieldId=$fieldId&skip=$skip&take=$take' : 'skip=$skip&take=$take';
    final res = await http.get(
      Uri.parse('$_baseUrl/zones?$query'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['zones'] as List<dynamic>? ?? []);
    return list.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Zone> createZone({required String name, required String fieldId}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/zones'),
      headers: _headers,
      body: jsonEncode({'name': name, 'fieldId': fieldId}),
    );
    _check(res);
    return Zone.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Zone> updateZone({required String id, required String name}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/zones/$id'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    _check(res);
    return Zone.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteZone(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/zones/$id'),
      headers: _headers,
    );
    _check(res);
  }

  // ── Valves ─────────────────────────────────────────────────────────────────
  Future<List<Valve>> getValves({String? zoneId, int skip = 0, int take = 100}) async {
    final query = zoneId != null ? 'zoneId=$zoneId&skip=$skip&take=$take' : 'skip=$skip&take=$take';
    final res = await http.get(
      Uri.parse('$_baseUrl/valves?$query'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['valves'] as List<dynamic>? ?? []);
    return list.map((e) => Valve.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Valve> createValve({required String name, required String zoneId}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/valves'),
      headers: _headers,
      body: jsonEncode({'name': name, 'zoneId': zoneId}),
    );
    _check(res);
    return Valve.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Valve> updateValve({required String id, required String name}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/valves/$id'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    _check(res);
    return Valve.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteValve(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/valves/$id'),
      headers: _headers,
    );
    _check(res);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/customers?take=200'),
      headers: _headers,
    );
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['customers'] ?? []);
  }
}
