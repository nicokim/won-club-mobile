import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://won-club.com/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (kDebugMode) {
      print('🔑 Token para API: ${token?.substring(0, 20)}...');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    if (kDebugMode) {
      print('🌐 GET: $baseUrl$endpoint');
    }
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('✅ GET success: ${response.statusCode}');
      }
      return json.decode(response.body);
    } else {
      if (kDebugMode) {
        print('❌ GET failed: ${response.statusCode} - ${response.body}');
      }
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    if (kDebugMode) {
      print('🌐 POST: $baseUrl$endpoint');
    }
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (kDebugMode) {
        print('✅ POST success: ${response.statusCode}');
      }
      return json.decode(response.body);
    } else {
      if (kDebugMode) {
        print('❌ POST failed: ${response.statusCode} - ${response.body}');
      }
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    if (kDebugMode) {
      print('🌐 PUT: $baseUrl$endpoint');
    }
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('✅ PUT success: ${response.statusCode}');
      }
      return json.decode(response.body);
    } else {
      if (kDebugMode) {
        print('❌ PUT failed: ${response.statusCode} - ${response.body}');
      }
      throw Exception('Failed to update data: ${response.statusCode}');
    }
  }

  Future<void> delete(String endpoint) async {
    final headers = await _getHeaders();
    if (kDebugMode) {
      print('🌐 DELETE: $baseUrl$endpoint');
    }
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print('❌ DELETE failed: ${response.statusCode} - ${response.body}');
      }
      throw Exception('Failed to delete data: ${response.statusCode}');
    } else {
      if (kDebugMode) {
        print('✅ DELETE success: ${response.statusCode}');
      }
    }
  }
}
