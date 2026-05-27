import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceService {
  static const String baseUrl = 'http://localhost:4051/api';

  /// Uploads a list of validated IMEI strings to the backend.
  /// Returns the decoded JSON response body.
  static Future<Map<String, dynamic>> uploadDevices({
    required List<String> imeis,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/upload'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'imeis': imeis}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        body['error'] ?? 'Upload failed (${response.statusCode})',
      );
    }

    return body;
  }
}
