// halkan soo dhig koodhkaaga Dart ee faylka serrvices/api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crop_model.dart';
import '../models/field_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your local IP for physical devices
  static const String baseUrl = "http://localhost:5000/api";

  // --- 1. AUTHENTICATION ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': "Server unreachable"};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': "Registration failed"};
    }
  }

  Future<bool> changePassword(int userId, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/auth/change-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'user_id': userId,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Password Update Error: $e");
      return false;
    }
  }

  // --- 2. USER MANAGEMENT (ADMIN & FARMER) ---

  Future<List<dynamic>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); 

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token', 
          'Content-Type': 'application/json',
        },
      );

      debugPrint("User API Status: ${response.statusCode}");
      debugPrint("User API Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // If your API returns { "users": [...] } instead of just [...]
        if (data is Map && data.containsKey('users')) {
          return data['users'];
        }
        
        return data as List<dynamic>;
      } else {
        debugPrint("Server Error: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getFarmers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/farmers'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error fetching farmers: $e");
    }
    return [];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- 3. FIELD MANAGEMENT ---

  Future<List<Field>> getFields() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getInt('user_id')?.toString(); 
    final String? role = prefs.getString('role');

    try {
      final uri = Uri.parse("$baseUrl/fields").replace(queryParameters: {
        'user_id': userId ?? '',
        'role': role ?? '',
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Field.fromJson(item)).toList();
      }
    } catch (e) {
      print("Fetch Error: $e");
    }
    return [];
  }

  Future<bool> addField(Field field) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/fields"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(field.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchaseField(int fieldId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/fields/purchase"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'field_id': fieldId,
          'user_id': userId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Purchase Error: $e");
      return false;
    }
  }

  // --- 4. CROP MANAGEMENT ---

  Future<List<Crop>> getCrops() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/crops"));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Crop.fromJson(item)).toList();
      }
    } catch (e) {
      print("Fetch Error: $e");
    }
    return [];
  }

  Future<bool> addCrop(Crop crop) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/crops"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(crop.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCrop(int id, Crop crop) async {
    final response = await http.put(
      Uri.parse("$baseUrl/crops/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(crop.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteCrop(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/crops/$id"));
    return response.statusCode == 200;
  }

  // --- 5. WEATHER DATA ---

  Future<Map<String, dynamic>> getWeatherData(String city) async {
    const apiKey = "609c258d4a46087d4032f5d9333364f2"; 
    final url = "https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? jsonDecode(response.body) : {};
    } catch (e) {
      return {};
    }
  }
}