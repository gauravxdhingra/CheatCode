import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/problem.dart';

class ApiService {
  // Change to your Mac's local IP
  static const String baseUrl = 'http://192.168.0.199:8000';
  static const String _cachedFeedKey = 'cached_feed';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const int _cacheDurationHours = 24;

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<String> createUser({
    required String email,
    required String role,
    String? name,
    String? interviewDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'role': role,
        if (name != null) 'name': name,
        if (interviewDate != null) 'interview_date': interviewDate,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userId = data['id'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      return userId;
    }

    if (response.statusCode == 409 || response.statusCode == 500) {
      return await _getUserByEmail(email);
    }

    throw Exception('Failed to create user: ${response.body}');
  }

  static Future<String> _getUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/by-email/$email'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    }
    throw Exception('User not found');
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  static Future<List<Problem>> getFeed(String userId) async {
    final cached = await _getCachedFeed();
    if (cached != null) return cached;

    final response = await http.get(
      Uri.parse('$baseUrl/feed/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final problems = (data['problems'] as List)
          .map((p) => Problem.fromJson(p))
          .toList();
      await _cacheFeed(response.body);
      return problems;
    }

    throw Exception('Failed to fetch feed: ${response.body}');
  }

  static Future<List<Problem>?> _getCachedFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    final cached = prefs.getString(_cachedFeedKey);
    if (timestamp == null || cached == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _cacheDurationHours * 60 * 60 * 1000) return null;
    final data = jsonDecode(cached);
    return (data['problems'] as List).map((p) => Problem.fromJson(p)).toList();
  }

  static Future<void> _cacheFeed(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedFeedKey, rawJson);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearFeedCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedFeedKey);
    await prefs.remove(_cacheTimestampKey);
  }

  // ── Answer validation ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> validateAnswer({
    required String userId,
    required String problemId,
    required String userAnswer,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/answers/$userId/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'problem_id': problemId,
        'user_answer': userAnswer,
      }),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Validation failed: ${response.body}');
  }

  // ── Solved today ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> getSolvedToday(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/answers/$userId/solved-today'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> markUnsolved({
    required String userId,
    required String problemId,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/answers/$userId/unsolved/$problemId'),
    );
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  static Future<void> updateProgress({
    required String userId,
    required String problemId,
    required String status,
    int? timeToSolve,
    int hintsUsed = 0,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/progress/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'problem_id': problemId,
        'status': status,
        if (timeToSolve != null) 'time_to_solve': timeToSolve,
        'hints_used': hintsUsed,
      }),
    );
  }

  static Future<Map<String, dynamic>> getStreak(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/$userId/streak'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'streak': 0, 'solved_today': 0};
  }
}
