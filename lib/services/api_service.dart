import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.100.35:8000/api";

  // =========================
  // AUTH
  // =========================
  static Future<Map<String, dynamic>> login(
      String identifier, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Accept": "application/json",
      },
      body: {
        "identifier": identifier,
        "password": password,
      },
    );

    return _handleResponse(response);
  }

static Future<Map<String, dynamic>> register({
  required String name,
  String? email,
  String? phone,
  required String password,
  String? address,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/register"),
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "name": name,
      "email": email,
      "phone": phone,
      "password": password,
      "address": address,
    }),
  );

  return jsonDecode(response.body);
}
  static Future<void> logout(String? token) async {
  await http.post(
    Uri.parse("$baseUrl/logout"),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    },
  );
}
  // =========================
  // SERVICES
  // =========================
  static Future<List> getServices(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/services"),
      headers: _authHeader(token),
    );

    return _handleListResponse(response);
  }

  // =========================
  // CREATE APPOINTMENT
  // =========================
  static Future<Map<String, dynamic>> createAppointment(
    String token,
    int serviceId,
    String date,
    String time,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/appointments"),
      headers: _authHeader(token, json: true),
      body: jsonEncode({
        "service_id": serviceId,
        "date": date,
        "time": time,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? "Erreur création rendez-vous");
    }

    return data;
  }

  // =========================
  // GET APPOINTMENTS
  // =========================
  static Future<List> getAppointments(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/appointments"),
      headers: _authHeader(token),
    );

    return _handleListResponse(response);
  }

  // =========================
  // GET SINGLE APPOINTMENT
  // =========================
  static Future<Map<String, dynamic>> getAppointment(
    String token,
    int id,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/appointments/$id"),
      headers: _authHeader(token),
    );

    return _handleResponse(response);
  }

  // =========================
  // PRESCRIPTION BY APPOINTMENT (IMPORTANT)
  // =========================
  static Future<Map<String, dynamic>?> getPrescription(
    String token,
    int appointmentId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/appointments/$appointmentId/prescription"),
      headers: _authHeader(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // =========================
  // PHARMACY SCAN (QR PRESCRIPTION)
  // =========================
  static Future<Map<String, dynamic>?> scanPrescription(
    String token,
    String qrCode,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/pharmacy/scan"),
      headers: _authHeader(token, json: true),
      body: jsonEncode({
        "qr_code": qrCode,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // =========================
  // HELPERS
  // =========================
  static Map<String, String> _authHeader(
    String token, {
    bool json = false,
  }) {
    return {
      "Authorization": "Bearer $token",
      if (json) "Content-Type": "application/json",
    };
  }

  // =========================
// HOME DATA (DASHBOARD PATIENT)
// =========================
static Future<Map<String, dynamic>> getHomeData(String token) async {
  final response = await http.get(
    Uri.parse("$baseUrl/home"),
    headers: _authHeader(token),
  );

  return _handleResponse(response);
}

// =========================
// NOTIFICATIONS
// =========================
static Future<List> getNotifications(String token) async {
  final response = await http.get(
    Uri.parse("$baseUrl/notifications"),
    headers: _authHeader(token),
  );

  return _handleListResponse(response);
}

  static Map<String, dynamic> _handleResponse(
      http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? "Erreur API");
  }

  static List _handleListResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception("Erreur API");
  }

static Future<Map<String, dynamic>> getProfile(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/profile/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Erreur profil');
  }
}
static Future<Map<String, dynamic>> updateProfile(
  String token,
  Map<String, dynamic> data,
) async {
  final response = await http.put(
    Uri.parse("$baseUrl/profile/update"),
    headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      "Content-Type": "application/json",
    },
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception("Erreur mise à jour");
}
}