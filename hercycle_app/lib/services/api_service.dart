import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static const FlutterSecureStorage storage = FlutterSecureStorage();
  static const String _registrationKey = "has_registered";
  static const String _usernameKey = "cached_username";
  static const String _emailKey = "cached_email";
  static const String _weeklyInsightsKey = "pref_weekly_insights";
  static const String _cycleReminderKey = "pref_cycle_reminders";

  // 🔐 LOGIN
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: "access", value: data["access"]);
      return true;
    }
    return false;
  }

  // 🌸 REGISTER
  static Future<bool> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      await storage.write(key: _registrationKey, value: 'true');
      return true;
    }
    return false;
  }

  // ✅ STATE
  static Future<bool> hasRegistered() async {
    final value = await storage.read(key: _registrationKey);
    return value == 'true';
  }

  static Future<Map<String, dynamic>?> fetchQuizProfile() async {
    final token = await storage.read(key: "access");
    final response = await http.get(
      Uri.parse("$baseUrl/quiz/profile/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await storage.read(key: "access");
    if (token == null) {
      return null;
    }
    final response = await http.get(
      Uri.parse("$baseUrl/users/profile/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }

  static Future<http.Response> updateUserProfile({
    String? username,
    String? email,
    String? password,
  }) async {
    final token = await storage.read(key: "access");
    final payload = <String, String>{};
    if (username != null) {
      payload["username"] = username;
    }
    if (email != null) {
      payload["email"] = email;
    }
    if (password != null) {
      payload["password"] = password;
    }
    if (token == null) {
      return http.Response("Unauthorized", 401);
    }

    return await http.patch(
      Uri.parse("$baseUrl/users/profile/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );
  }

  static Future<List<dynamic>> fetchCycles() async {
    final token = await storage.read(key: "access");
    final response = await http.get(
      Uri.parse("$baseUrl/cycles/create/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
    }
    return [];
  }

  static Future<bool> updateCycle({
    required int id,
    required String startDate,
    required int cycleLength,
    required int periodLength,
  }) async {
    final token = await storage.read(key: "access");
    final response = await http.put(
      Uri.parse("$baseUrl/cycles/log/$id/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "start_date": startDate,
        "cycle_length": cycleLength,
        "period_length": periodLength,
      }),
    );

    return response.statusCode == 200;
  }

  // 🌸 SAVE CYCLE
  static Future<bool> saveCycle({
    required String startDate,
    required int cycleLength,
    required int periodLength,
  }) async {
    final token = await storage.read(key: "access");

    final response = await http.post(
      Uri.parse("$baseUrl/cycles/create/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "start_date": startDate,
        "cycle_length": cycleLength,
        "period_length": periodLength,
      }),
    );

    if (response.statusCode != 201) {
      print('Save cycle error: ${response.statusCode} - ${response.body}');
    }
    return response.statusCode == 201;
  }

  // 🗑️ DELETE CYCLE
  static Future<bool> deleteCycle(dynamic cycleId) async {
    final token = await storage.read(key: "access");

    final response = await http.delete(
      Uri.parse("$baseUrl/cycles/log/$cycleId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }

  // 🔮 GET PREDICTION  ✅ INSIDE CLASS
  static Future<Map<String, dynamic>?> getPrediction() async {
    final token = await storage.read(key: "access");

    final response = await http.get(
      Uri.parse("$baseUrl/predict/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> &&
          data.containsKey("predicted_next_period")) {
        return data;
      }
    }
    return null;
  }

  // 🧠 SUBMIT QUIZ
  static Future<bool> submitQuiz(Map<String, dynamic> answers) async {
    final token = await storage.read(key: "access");

    final response = await http.post(
      Uri.parse("$baseUrl/quiz/submit/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(answers),
    );

    return response.statusCode == 200;
  }

  static Future<void> cacheUserInfo({String? username, String? email}) async {
    if (username != null) {
      await storage.write(key: _usernameKey, value: username);
    }
    if (email != null) {
      await storage.write(key: _emailKey, value: email);
    }
  }

  static Future<Map<String, String?>> loadUserInfo() async {
    final username = await storage.read(key: _usernameKey);
    final email = await storage.read(key: _emailKey);
    return {"username": username, "email": email};
  }

  static Future<Map<String, bool>> loadPreferences() async {
    final weekly = await storage.read(key: _weeklyInsightsKey);
    final reminders = await storage.read(key: _cycleReminderKey);
    return {
      "weeklyInsights": weekly != 'false',
      "cycleReminders": reminders != 'false',
    };
  }

  static Future<void> cachePreferences({
    bool? weeklyInsights,
    bool? cycleReminders,
  }) async {
    if (weeklyInsights != null) {
      await storage.write(
        key: _weeklyInsightsKey,
        value: weeklyInsights ? 'true' : 'false',
      );
    }
    if (cycleReminders != null) {
      await storage.write(
        key: _cycleReminderKey,
        value: cycleReminders ? 'true' : 'false',
      );
    }
  }

  static Future<bool> usernameExists(String username) async {
    final uri = Uri.parse(
      "$baseUrl/users/exists/?username=${Uri.encodeQueryComponent(username)}",
    );
    final response = await http.get(
      uri,
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode != 200) {
      return false;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded['exists'] == true;
    }
    return false;
  }

  // 🚪 LOGOUT
  static Future<void> logout() async {
    // Clear stored tokens and user data
    await storage.delete(key: "access");
    await storage.delete(key: _registrationKey);
    await storage.delete(key: _usernameKey);
    await storage.delete(key: _emailKey);
    await storage.delete(key: _weeklyInsightsKey);
    await storage.delete(key: _cycleReminderKey);
  }

  // 📝 DAILY LOGS

  /// Save or update a daily log
  static Future<bool> saveDailyLog(Map<String, dynamic> logData) async {
    final token = await storage.read(key: "access");

    final response = await http.post(
      Uri.parse("$baseUrl/daily-logs/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(logData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('Save daily log error: ${response.statusCode} - ${response.body}');
    }
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Fetch all daily logs for the user
  static Future<List<dynamic>> fetchDailyLogs({
    String? startDate,
    String? endDate,
    int limit = 30,
  }) async {
    final token = await storage.read(key: "access");

    // Build query parameters
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse(
      "$baseUrl/daily-logs/",
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
    }
    return [];
  }

  /// Fetch a daily log by date
  static Future<Map<String, dynamic>?> getDailyLogByDate(String date) async {
    final token = await storage.read(key: "access");

    final response = await http.get(
      Uri.parse("$baseUrl/daily-logs/date/$date/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return null;
  }

  /// Delete a daily log
  static Future<bool> deleteDailyLog(int logId) async {
    final token = await storage.read(key: "access");

    final response = await http.delete(
      Uri.parse("$baseUrl/daily-logs/$logId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }
}
